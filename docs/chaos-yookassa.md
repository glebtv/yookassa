# YooKassa Smart Payment Integration Guide

## Overview

This guide uses the `yookassa` gem for both API calls and webhook security handling.
Do not re-implement webhook signature checks in your app: this integration uses a
secret URL token + source IP allowlist + API re-fetch verification.

## Payment flow

```
User taps "Pay" -> backend creates payment via gem -> user pays on YooKassa page ->
YooKassa sends webhook -> gem controller verifies webhook -> app applies business logic
```

## 1) Install and configure the gem

```ruby
# Gemfile
gem "yookassa"
```

```ruby
# config/initializers/yookassa.rb
Yookassa.configure do |config|
  config.shop_id = ENV.fetch("YOOKASSA_SHOP_ID")
  config.api_key = ENV.fetch("YOOKASSA_SECRET_KEY")

  # Required: long random token used in webhook route path.
  config.webhook_token = ENV.fetch("YOOKASSA_WEBHOOK_TOKEN")

  # Optional override, if you need a custom list.
  # Defaults are from YooKassa docs:
  # https://yookassa.ru/developers/using-api/webhooks#ip
  # config.webhook_allowed_ips = ["185.71.76.0/27", ...]
end
```

## 2) Create payments with gem client

```ruby
payload = {
  amount: {
    value: "100.00",
    currency: "RUB"
  },
  capture: true,
  confirmation: {
    type: "redirect",
    return_url: "https://example.com/payment/return"
  },
  description: "Order 123"
}

payment = Yookassa.payments.create(payment: payload)
confirmation_url = payment.confirmation.confirmation_url
```

## 3) Mount gem webhook engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Yookassa::Engine => "/yookassa"
end
```

Default webhook endpoint:

- `POST /yookassa/webhooks/:token`

Your YooKassa dashboard webhook URL must include the configured token value, for example:

- `https://your-domain.com/yookassa/webhooks/<long-random-token>`

## 4) Add app-specific webhook logic by inheritance

`Yookassa::WebhooksController` handles authenticity checks. Override only processing.

```ruby
# app/controllers/yookassa_events_controller.rb
class YookassaEventsController < Yookassa::WebhooksController
  private

  def process_webhook(payload)
    event = payload["event"] || payload["type"]
    object = payload["object"] || payload.dig("data", "object")
    return unless object

    case event
    when "payment.succeeded"
      # apply balance / mark paid in your app
    when "payment.canceled"
      # mark failed in your app
    end
  end
end
```

```ruby
# config/routes.rb
post "/webhooks/yookassa/:token", to: "yookassa_events#create"
```

## Webhook security model used by gem

The default controller accepts webhook only if all checks pass:

1. route includes token and it matches `Yookassa.config.webhook_token`
2. source address from `request.remote_ip` is in allowlist
3. webhook object `id` + `status` matches a fresh API fetch

This approach intentionally does not use HMAC signature headers.

## Defaults and allowlist override

Default allowed IP ranges in gem:

- `185.71.76.0/27`
- `185.71.77.0/27`
- `77.75.153.0/25`
- `77.75.156.11`
- `77.75.156.35`
- `77.75.154.128/25`
- `2a02:5180::/32`

Source: https://yookassa.ru/developers/using-api/webhooks#ip

If needed:

```ruby
Yookassa.configure do |config|
  config.webhook_allowed_ips = ["203.0.113.10"]
end
```
