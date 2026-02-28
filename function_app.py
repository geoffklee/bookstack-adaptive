import json
import logging
import os
import threading

import azure.functions as func
import requests

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


def _build_adaptive_card(payload: dict) -> dict:
    """Convert a BookStack webhook payload into an Adaptive Card dict."""
    event = payload.get("event", "bookstack.event")
    title = event.replace(".", " ").replace("_", " ").title()
    text = payload.get("text", "")
    triggered_by = payload.get("triggered_by", {})
    triggered_by_name = triggered_by.get("name", "") if isinstance(triggered_by, dict) else str(triggered_by)
    triggered_at = payload.get("triggered_at", "")
    webhook_name = payload.get("webhook_name", "")
    url = payload.get("url")

    body = [
        {
            "type": "TextBlock",
            "text": title,
            "weight": "Bolder",
            "size": "Large",
            "wrap": True,
        },
        {
            "type": "TextBlock",
            "text": text,
            "wrap": True,
        },
        {
            "type": "FactSet",
            "facts": [
                {"title": "Triggered by", "value": triggered_by_name},
                {"title": "Triggered at", "value": triggered_at},
                {"title": "Webhook", "value": webhook_name},
            ],
        },
    ]

    actions = []
    if url:
        actions.append({
            "type": "Action.OpenUrl",
            "title": "Open",
            "url": url,
        })

    card: dict = {
        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.5",
        "body": body,
    }
    if actions:
        card["actions"] = actions

    return card


def _post_to_downstream(card: dict, webhook_url: str, auth_key: str) -> None:
    """Send the Adaptive Card to the downstream webhook in a background thread."""
    payload = {"content": card, "key": auth_key}
    try:
        response = requests.post(webhook_url, json=payload, timeout=30)
        response.raise_for_status()
        logging.info("Downstream webhook responded with status %s", response.status_code)
    except requests.RequestException as exc:
        logging.error("Failed to post to downstream webhook: %s", exc)


@app.route(route="bookstack-webhook", methods=["POST"])
def bookstack_webhook(req: func.HttpRequest) -> func.HttpResponse:
    """HTTP-triggered function that receives a BookStack webhook and forwards it as an Adaptive Card."""
    webhook_url = os.environ.get("OUTPUT_WEBHOOK_URL", "")
    auth_key = os.environ.get("OUTPUT_AUTH_KEY", "")

    if not webhook_url:
        logging.error("OUTPUT_WEBHOOK_URL is not configured")
        return func.HttpResponse("Server misconfiguration", status_code=500)

    try:
        payload = req.get_json()
    except ValueError:
        logging.error("Invalid JSON in request body")
        return func.HttpResponse("Invalid JSON", status_code=400)

    if not isinstance(payload, dict):
        logging.error("Request body must be a JSON object")
        return func.HttpResponse("Invalid payload", status_code=400)

    card = _build_adaptive_card(payload)

    thread = threading.Thread(
        target=_post_to_downstream,
        args=(card, webhook_url, auth_key),
        daemon=True,
    )
    thread.start()

    return func.HttpResponse("OK", status_code=200)
