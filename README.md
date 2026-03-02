# YooKassa API Ruby Client
[![Github Actions](https://github.com/PaymentInstruments/yookassa/actions/workflows/main.yml/badge.svg)](https://github.com/PaymentInstruments/yookassa/actions/workflows/main.yml)
[![Gem Version][gem-badger]][gem]
[![License](https://img.shields.io/github/license/paderinandrey/yookassa.svg)](https://github.com/paderinandrey/yookassa)


[gem-badger]: https://img.shields.io/gem/v/yookassa.svg?style=flat&color=blue
[gem]: https://rubygems.org/gems/yookassa

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yookassa'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yookassa

## Usage

### Configuration

First of all you need to setup credentials to use Yookassa.
You can configure your instance of Yookassa once in a application booting time. Ex. if you use rails, just put these lines into initializer file

```ruby
# config/initializers/yookassa.rb

Yookassa.configure do |config|
  config.shop_id = ENV.fetch('YOOKASSA_SHOP_ID') # or put your shop_id and api_key here directly
  config.api_key = ENV.fetch('YOOKASSA_API_KEY') # can be taken from Rails.credentials too
end
```

There are some cases, when you need to connect to different Yookassa accounts (say, your clients need to connect to Yookassa). That probably means that you run a marketplace or multitenant system. There is a solution for this one from Yookassa, see https://yookassa.ru/en/developers/special-solutions/checkout-for-platforms/basics or https://yookassa.ru/en/developers/partners-api/basics

If that is not your case, and you still have multiple shop_ids and api_keys, and need to handle all of them under one application, then you need to instantiate clients inline

```ruby
client1 = Yookassa::Payments.new(shop_id: 'shop_1', api_key: '123')
client2 = Yookassa::Payments.new(shop_id: 'shop_2', api_key: '456')
```

### Making Payments

#### Creating payment
```ruby
payload = {
    amount: {
        value:    100,
        currency: 'RUB'
    },
    capture:      true,
    confirmation: {
        type:       'redirect',
        return_url: return_url
    }
}

payment = Yookassa.payments.create(payment: payload)

# or

payments = Yookassa::Payments.new(shop_id: 'shop_1', api_key: '123')
payment = payments.create(payment: payload)
```

#### Other payment requests

```ruby
Yookassa.payments.find(payment_id: '12345')
Yookassa.payments.capture(payment_id: '12345')
Yookassa.payments.cancel(payment_id: '12345')
```

### Rails webhook endpoint (engine)

The gem ships with a Rails engine and a default webhook controller you can use directly.

1) Configure the webhook token and (optionally) allowed source IPs:

```ruby
# config/initializers/yookassa.rb
Yookassa.configure do |config|
  config.shop_id = ENV.fetch('YOOKASSA_SHOP_ID')
  config.api_key = ENV.fetch('YOOKASSA_API_KEY')

  # Random, long, secret token used in webhook URL path.
  config.webhook_token = ENV.fetch('YOOKASSA_WEBHOOK_TOKEN')

  # Optional override. Defaults come from YooKassa docs:
  # https://yookassa.ru/developers/using-api/webhooks#ip
  # config.webhook_allowed_ips = ['185.71.76.0/27', ...]
end
```

2) Mount the engine in routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Yookassa::Engine => '/yookassa'
end
```

This exposes:

- `POST /yookassa/webhooks/:token`

Set your YooKassa webhook URL to include the real token value, for example:

- `https://example.com/yookassa/webhooks/<long-random-token>`

The default `Yookassa::WebhooksController` verifies:

- token in URL path
- request source `request.remote_ip` is in allowlist
- webhook object matches fresh API fetch by `id` and `status`

No signature headers are used.

### Overriding webhook handling

In host app, inherit from the gem controller and implement business logic in `process_webhook`:

```ruby
# app/controllers/my_yookassa_webhooks_controller.rb
class MyYookassaWebhooksController < Yookassa::WebhooksController
  private

  def process_webhook(payload)
    object = payload['object'] || payload.dig('data', 'object')
    return unless object

    # Your app-specific processing
  end
end
```

Then route to your controller (keeping token in path):

```ruby
# config/routes.rb
post '/webhooks/yookassa/:token', to: 'my_yookassa_webhooks#create'
```

### Path to 1.0

**Настройки SDK API ЮKassa**
 - [x] Аутентификация
 - [ ] Статистические данные об используемом окружении
 - [ ] Получение информации о магазине
 - [ ] Работа с Webhook
 - [ ] Входящие уведомления

**Работа с платежами**
 - [x] Запрос на создание платежа
 - [ ] Запрос на создание платежа через билдер
 - [x] Запрос на частичное подтверждение платежа
 - [x] Запрос на отмену незавершенного платежа
 - [x] Получить информацию о платеже
 - [x] Получить список платежей с фильтрацией
 - [ ] Контракт на добавление платежа
 - [ ] Запись реальных валидных и невалидных запросов и ответов

**Работа с возвратами**
 - [x] Запрос на создание возврата
 - [ ] Запрос на создание возврата через билдер
 - [x] Получить информацию о возврате
 - [x] Получить список возвратов с фильтрацией
 - [ ] Контракт на добавление возврата
 - [ ] Запись реальных валидных и невалидных запросов и ответов

**Работа с чеками**
 - [x] Запрос на создание чека
 - [ ] Запрос на создание чека через билдер
 - [x] Получить информацию о чеке
 - [x] Получить список чеков с фильтрацией
 - [ ] Контракт на добавление возврата
 - [ ] Запись реальных валидных и невалидных запросов и ответов


## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/paderinandrey/yookassa/issues)
- Fix bugs and [submit pull requests](https://github.com/paderinandrey/yookassa/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
