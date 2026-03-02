# frozen_string_literal: true

require "ipaddr"
require "json"

module Yookassa
  class WebhooksController < ::ActionController::Base
    skip_before_action :verify_authenticity_token, raise: false

    def create
      payload = parsed_payload
      return head :unauthorized unless authentic_webhook?(payload)

      process_webhook(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def process_webhook(_payload)
      nil
    end

    def authentic_webhook?(payload)
      token_valid? && source_ip_allowed? && payload_matches_api_object?(payload)
    end

    def token_valid?
      token = params[:token].to_s
      configured_token = Yookassa.config.webhook_token.to_s
      return false if token.empty? || configured_token.empty?

      ActiveSupport::SecurityUtils.secure_compare(token, configured_token)
    end

    def source_ip_allowed?
      source_ip = request.remote_ip
      allowed_cidrs.any? { |cidr| IPAddr.new(cidr).include?(source_ip) }
    rescue IPAddr::InvalidAddressError
      false
    end

    def allowed_cidrs
      ips = Yookassa.config.webhook_allowed_ips
      return Yookassa::Config::DEFAULT_WEBHOOK_ALLOWED_IPS if ips.nil? || ips.empty?

      ips
    end

    def parsed_payload
      @parsed_payload ||= JSON.parse(request.raw_post)
    end

    def payload_matches_api_object?(payload)
      object = payload["object"] || payload.dig("data", "object")
      return false unless object.is_a?(Hash)

      object_id = object["id"].to_s
      object_status = object["status"].to_s
      return false if object_id.empty? || object_status.empty?

      fetched_object = fetch_object_from_api(payload, object_id)
      return false if fetched_object.nil?

      fetched_object.id == object_id && fetched_object.status == object_status
    rescue StandardError
      false
    end

    def fetch_object_from_api(payload, object_id)
      event_name = payload["event"].to_s
      event_name = payload["type"].to_s if event_name.empty?

      if event_name.start_with?("payment.")
        Yookassa.payments.find(payment_id: object_id)
      elsif event_name.start_with?("refund.")
        Yookassa.refunds.find(payment_id: object_id)
      end
    end
  end
end
