# frozen_string_literal: true

begin
  require "logger"
  require "rack/test"
  require "rails"
  require "action_controller/railtie"
  require "capybara"
  require "capybara/rspec"
  require "capybara/cuprite"
rescue LoadError
  nil
end

if defined?(Rails)
  require "yookassa/engine"
  require File.expand_path("../../app/controllers/yookassa/webhooks_controller", __dir__)

  class YookassaSpecBrowserController < ActionController::Base
    def index
      render inline: <<~HTML
        <!DOCTYPE html>
        <html>
          <body>
            <button id="send">Send webhook</button>
            <div id="result">pending</div>
            <script>
              document.getElementById("send").addEventListener("click", function() {
                fetch("/yookassa/webhooks/<%= Yookassa.config.webhook_token %>", {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({
                    event: "payment.succeeded",
                    object: { id: "browser-payment", status: "succeeded" }
                  })
                }).then(function(response) {
                  document.getElementById("result").textContent = String(response.status);
                });
              });
            </script>
          </body>
        </html>
      HTML
    end
  end

  class YookassaSpecCustomWebhooksController < Yookassa::WebhooksController
    class_attribute :last_payload, default: nil

    private

    def process_webhook(payload)
      self.class.last_payload = payload
    end
  end

  class YookassaSpecApp < Rails::Application
    config.root = File.expand_path("../..", __dir__)
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base"
    config.logger = Logger.new(nil)
    config.hosts << "www.example.com"
    config.hosts << "example.org"
    config.hosts << "localhost"
    config.hosts << "127.0.0.1"
    config.consider_all_requests_local = true
  end

  YookassaSpecApp.initialize!

  YookassaSpecApp.routes.draw do
    mount Yookassa::Engine => "/yookassa"
    post "/custom-yookassa/:token", to: "yookassa_spec_custom_webhooks#create"
    get "/browser", to: "yookassa_spec_browser#index"
  end

  Capybara.app = YookassaSpecApp
  Capybara.server = :webrick
  Capybara.default_max_wait_time = 5
  Capybara.register_driver(:cuprite) do |app|
    Capybara::Cuprite::Driver.new(app, headless: true)
  end

  RSpec.configure do |config|
    config.include Rack::Test::Methods

    config.define_derived_metadata(file_path: %r{/spec/yookassa/webhooks_}) do |metadata|
      metadata[:rails] = true
    end

    config.before(:each, rails: true) do
      Yookassa.configure do |yookassa_config|
        yookassa_config.shop_id = "shop-id"
        yookassa_config.api_key = "api-key"
        yookassa_config.webhook_token = "secret-token"
        yookassa_config.webhook_allowed_ips = Yookassa::Config::DEFAULT_WEBHOOK_ALLOWED_IPS.dup
      end

      YookassaSpecCustomWebhooksController.last_payload = nil
    end
  end
end
