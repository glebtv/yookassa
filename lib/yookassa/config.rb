# frozen_string_literal: true

module Yookassa
  class Config
    # Source: https://yookassa.ru/developers/using-api/webhooks#ip
    DEFAULT_WEBHOOK_ALLOWED_IPS = [
      "185.71.76.0/27",
      "185.71.77.0/27",
      "77.75.153.0/25",
      "77.75.156.11",
      "77.75.156.35",
      "77.75.154.128/25",
      "2a02:5180::/32"
    ].freeze

    attr_accessor :shop_id, :api_key, :webhook_token, :webhook_allowed_ips

    def initialize
      @webhook_allowed_ips = DEFAULT_WEBHOOK_ALLOWED_IPS.dup
    end
  end
end
