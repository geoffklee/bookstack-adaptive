"""Unit tests for function_app.py"""
import json
import sys
import types
import unittest
from unittest.mock import MagicMock, patch


def _load_function_app():
    """Load function_app module with a minimal azure.functions stub."""
    azure_mod = types.ModuleType("azure")
    af = types.ModuleType("azure.functions")

    class FakeApp:
        def __init__(self, **kw):
            pass

        def route(self, **kw):
            def decorator(fn):
                return fn

            return decorator

    class FakeHttpResponse:
        def __init__(self, body, status_code=200):
            self.body = body
            self.status_code = status_code

    class FakeAuthLevel:
        ANONYMOUS = "anonymous"

    af.FunctionApp = FakeApp
    af.AuthLevel = FakeAuthLevel
    af.HttpRequest = object
    af.HttpResponse = FakeHttpResponse

    sys.modules["azure"] = azure_mod
    sys.modules["azure.functions"] = af

    import importlib.util
    import os

    spec = importlib.util.spec_from_file_location(
        "function_app",
        os.path.join(os.path.dirname(__file__), "function_app.py"),
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


mod = _load_function_app()


class TestBuildAdaptiveCard(unittest.TestCase):
    def _full_payload(self):
        return {
            "event": "page_create",
            "text": "Page was created",
            "triggered_at": "2024-01-15T10:30:00Z",
            "triggered_by": {"id": 1, "name": "Admin"},
            "webhook_name": "Teams Notifications",
            "url": "https://example.com/page/1",
        }

    def test_schema_and_version(self):
        card = mod._build_adaptive_card(self._full_payload())
        self.assertEqual(card["$schema"], "http://adaptivecards.io/schemas/adaptive-card.json")
        self.assertEqual(card["version"], "1.5")
        self.assertEqual(card["type"], "AdaptiveCard")

    def test_title_derived_from_event(self):
        card = mod._build_adaptive_card(self._full_payload())
        title_block = card["body"][0]
        self.assertEqual(title_block["type"], "TextBlock")
        self.assertIn("Page", title_block["text"])
        self.assertEqual(title_block["weight"], "Bolder")

    def test_text_block_present(self):
        card = mod._build_adaptive_card(self._full_payload())
        texts = [b["text"] for b in card["body"] if b["type"] == "TextBlock"]
        self.assertIn("Page was created", texts)

    def test_facts_present(self):
        card = mod._build_adaptive_card(self._full_payload())
        fact_sets = [b for b in card["body"] if b["type"] == "FactSet"]
        self.assertEqual(len(fact_sets), 1)
        fact_titles = [f["title"] for f in fact_sets[0]["facts"]]
        self.assertIn("Triggered by", fact_titles)
        self.assertIn("Triggered at", fact_titles)
        self.assertIn("Webhook", fact_titles)
        fact_values = {f["title"]: f["value"] for f in fact_sets[0]["facts"]}
        self.assertEqual(fact_values["Triggered by"], "Admin")
        self.assertEqual(fact_values["Triggered at"], "2024-01-15T10:30:00Z")
        self.assertEqual(fact_values["Webhook"], "Teams Notifications")

    def test_action_open_url_when_url_present(self):
        card = mod._build_adaptive_card(self._full_payload())
        self.assertIn("actions", card)
        action = card["actions"][0]
        self.assertEqual(action["type"], "Action.OpenUrl")
        self.assertEqual(action["url"], "https://example.com/page/1")

    def test_no_actions_when_url_missing(self):
        payload = self._full_payload()
        del payload["url"]
        card = mod._build_adaptive_card(payload)
        self.assertNotIn("actions", card)

    def test_triggered_by_as_non_dict(self):
        payload = self._full_payload()
        payload["triggered_by"] = "SomeUser"
        card = mod._build_adaptive_card(payload)
        fact_set = next(b for b in card["body"] if b["type"] == "FactSet")
        triggered_by_value = next(f["value"] for f in fact_set["facts"] if f["title"] == "Triggered by")
        self.assertEqual(triggered_by_value, "SomeUser")

    def test_missing_optional_fields(self):
        card = mod._build_adaptive_card({"event": "page_update"})
        self.assertEqual(card["type"], "AdaptiveCard")
        self.assertNotIn("actions", card)


class TestPostToDownstream(unittest.TestCase):
    def test_successful_post(self):
        fake_response = MagicMock()
        fake_response.status_code = 200
        fake_response.raise_for_status = MagicMock()
        with patch("requests.post", return_value=fake_response) as mock_post:
            mod._post_to_downstream({"type": "AdaptiveCard"}, "https://example.com/hook", "secret-key")
        mock_post.assert_called_once()
        call_kwargs = mock_post.call_args
        body = call_kwargs[1]["json"] if "json" in call_kwargs[1] else call_kwargs[0][1]
        self.assertEqual(body["key"], "secret-key")
        self.assertIn("content", body)

    def test_failed_post_logs_error(self):
        import requests as req_mod

        with patch("requests.post", side_effect=req_mod.ConnectionError("conn refused")):
            with self.assertLogs(level="ERROR") as log_ctx:
                mod._post_to_downstream({}, "https://bad.url/hook", "key")
        self.assertTrue(any("downstream webhook" in msg for msg in log_ctx.output))

    def test_auth_key_not_logged(self):
        import requests as req_mod

        with patch("requests.post", side_effect=req_mod.ConnectionError("conn refused")):
            with self.assertLogs(level="ERROR") as log_ctx:
                mod._post_to_downstream({}, "https://bad.url/hook", "super-secret-key")
        for msg in log_ctx.output:
            self.assertNotIn("super-secret-key", msg)


if __name__ == "__main__":
    unittest.main()
