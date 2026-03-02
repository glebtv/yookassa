# Webhooks

## Overview

The gem provides a Rails engine endpoint for YooKassa webhooks and a default controller
that performs security checks before running your app-specific logic.

Default endpoint after mounting engine:

- `POST /yookassa/webhooks/:token`

## Security model

The controller accepts a webhook only if all checks pass:

1. Route token matches configured `Yookassa.config.webhook_token`.
2. Source IP from `request.remote_ip` belongs to allowed CIDRs.
3. Webhook object `id` and `status` match a fresh API fetch (`payments.find` or `refunds.find`).

This follows YooKassa webhook guidance:

- https://yookassa.ru/developers/using-api/webhooks

## Default allowed IP ranges

From YooKassa docs (source: https://yookassa.ru/developers/using-api/webhooks#ip):

- `185.71.76.0/27`
- `185.71.77.0/27`
- `77.75.153.0/25`
- `77.75.156.11`
- `77.75.156.35`
- `77.75.154.128/25`
- `2a02:5180::/32`

## Configuration

```ruby
Yookassa.configure do |config|
  config.shop_id = ENV.fetch("YOOKASSA_SHOP_ID")
  config.api_key = ENV.fetch("YOOKASSA_API_KEY")
  config.webhook_token = ENV.fetch("YOOKASSA_WEBHOOK_TOKEN")

  # Optional override
  # config.webhook_allowed_ips = ["203.0.113.10"]
end
```

## Overriding controller behavior

Inherit from `Yookassa::WebhooksController` and override `process_webhook`.
All security checks remain in the base controller.

```ruby
class MyYookassaWebhooksController < Yookassa::WebhooksController
  private

  def process_webhook(payload)
    event = payload["event"]
    object = payload["object"]
    # app-specific logic
  end
end
```

Route example:

```ruby
post "/webhooks/yookassa/:token", to: "my_yookassa_webhooks#create"
```
