# frozen_string_literal: true

require "httpclient"
require "json"
require_relative "./entity/error"

module Yookassa
  class Client
    API_URL = "https://api.yookassa.ru/v3/"

    attr_reader :http

    def initialize(shop_id: Yookassa.config.shop_id, api_key: Yookassa.config.api_key, oauth_token: nil)
      @http = HTTPClient.new(
        default_header: { "Accept" => "application/json" },
        force_basic_auth: true
      )

      if shop_id && api_key
        @http.set_auth(API_URL, shop_id, api_key)
      elsif oauth_token
        @http.default_header["Authorization"] = "Bearer #{oauth_token}"
      else
        message = "Specify `shop_id` and `api_key` settings in a `.configure` block " \
                  "or pass `oauth_token` to a client"
        raise ConfigError, message
      end
    end

    private

    def get(endpoint, query: {})
      api_call { http.get("#{API_URL}#{endpoint}", query: query) }
    end

    def post(endpoint, idempotency_key:, payload: {})
      headers = json_headers.merge("Idempotence-Key" => idempotency_key)
      api_call { http.post("#{API_URL}#{endpoint}", body: JSON.generate(payload), header: headers) }
    end

    def delete(endpoint, idempotency_key:)
      api_call { http.delete("#{API_URL}#{endpoint}", header: { "Idempotence-Key" => idempotency_key }) }
    end

    def api_call
      response = yield if block_given?
      body = JSON.parse(response.body.to_s, symbolize_names: true)
      return body if response.status.between?(200, 299)

      Entity::Error.new(**body)
    end

    def json_headers
      { "Content-Type" => "application/json" }
    end
  end
end
