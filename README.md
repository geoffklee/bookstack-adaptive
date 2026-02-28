# Bookstack Adaptive

Azure Function app (Python v2 programming model) that receives [BookStack](https://www.bookstackapp.com/) webhook events via HTTP POST, converts them to [Adaptive Cards](https://adaptivecards.io/), and forwards the result asynchronously to a downstream webhook (e.g. Microsoft Teams).

## Endpoint

```
POST /api/bookstack-webhook
```

The function returns **HTTP 200** immediately and performs the downstream POST in a background thread.

## Configuration

Set the following Application Settings (environment variables):

| Setting | Description |
|---|---|
| `OUTPUT_WEBHOOK_URL` | Downstream webhook URL to forward the Adaptive Card to |
| `OUTPUT_AUTH_KEY` | Auth key included as `key` in the downstream POST body |

## Local Development

### Prerequisites

- Python 3.11+
- [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azurite](https://learn.microsoft.com/azure/storage/common/storage-use-azurite) (local storage emulator) or a real Azure Storage connection string

### Steps

1. **Clone and install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

2. **Create local settings**

   ```bash
   cp local.settings.json.example local.settings.json
   # Edit local.settings.json and fill in OUTPUT_WEBHOOK_URL and OUTPUT_AUTH_KEY
   ```

3. **Start Azurite** (in a separate terminal)

   ```bash
   azurite --silent
   ```

4. **Start the function**

   ```bash
   func start
   ```

   The function will be available at `http://localhost:7071/api/bookstack-webhook`.

## Example Request

```bash
curl -X POST http://localhost:7071/api/bookstack-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event": "page_create",
    "text": "Page \"Getting Started\" was created",
    "triggered_at": "2024-01-15T10:30:00.000000Z",
    "triggered_by": {
      "id": 1,
      "name": "Admin User",
      "slug": "admin"
    },
    "triggered_by_profile_url": "https://bookstack.example.com/user/admin",
    "webhook_id": 1,
    "webhook_name": "Teams Notifications",
    "url": "https://bookstack.example.com/books/my-book/page/getting-started",
    "related_item": {
      "id": 42,
      "name": "Getting Started",
      "slug": "getting-started"
    }
  }'
```

Expected response: `200 OK` with body `OK`.

## Downstream POST Body

The function forwards the following JSON to `OUTPUT_WEBHOOK_URL`:

```json
{
  "content": { "...adaptive card json..." },
  "key": "<OUTPUT_AUTH_KEY value>"
}
```

## Adaptive Card Fields

| Card element | Source field |
|---|---|
| Title | `event` (formatted) |
| Body text | `text` |
| Fact: Triggered by | `triggered_by.name` |
| Fact: Triggered at | `triggered_at` |
| Fact: Webhook | `webhook_name` |
| Action.OpenUrl | `url` (if present) |