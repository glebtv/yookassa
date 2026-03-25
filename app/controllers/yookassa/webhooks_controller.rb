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
      token_ok = token_valid?
      ip_ok = source_ip_allowed?
      api_ok = payload_matches_api_object?(payload)

      unless token_ok && ip_ok && api_ok
        Rails.logger.info("[Yookassa Webhook] Auth failed: token=#{token_ok}, ip=#{ip_ok}, api=#{api_ok}, remote_ip=#{request.remote_ip}")
      end

      token_ok && ip_ok && api_ok
    end

    def token_valid?
      token = params[:token].to_s
      configured_token = Yookassa.config.webhook_token.to_s
      if token.empty? || configured_token.empty?
        Rails.logger.info("[Yookassa Webhook] Token validation failed: param_token=#{token.empty? ? "empty" : "present"}, configured_token=#{configured_token.empty? ? "empty" : "present"}")
        return false
      end

      if token.bytesize != configured_token.bytesize
        Rails.logger.info("[Yookassa Webhook] Token comparison: false (length mismatch)")
        return false
      end

      result = ActiveSupport::SecurityUtils.secure_compare(token, configured_token)
      Rails.logger.info("[Yookassa Webhook] Token comparison: #{result}")
      result
    end

    def source_ip_allowed?
      source_ip = request.remote_ip
      allowed = allowed_cidrs.any? { |cidr| IPAddr.new(cidr).include?(source_ip) }
      Rails.logger.info("[Yookassa Webhook] IP check: remote_ip=#{source_ip}, allowed=#{allowed}, cidrs=#{allowed_cidrs}")
      allowed
    rescue IPAddr::InvalidAddressError => e
      Rails.logger.info("[Yookassa Webhook] IP check failed: #{e.message}")
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
      object = extract_object(payload)
      unless object.is_a?(Hash)
        Rails.logger.info("[Yookassa Webhook] API object check failed: object is not a Hash")
        return false
      end

      object_id = object["id"].to_s
      object_status = object["status"].to_s
      if object_id.empty? || object_status.empty?
        Rails.logger.info("[Yookassa Webhook] API object check failed: object_id=#{object_id}, object_status=#{object_status}")
        return false
      end

      fetched_object = fetch_object_from_api(payload, object_id)
      if fetched_object.nil?
        Rails.logger.info("[Yookassa Webhook] API object check failed: could not fetch object #{object_id}")
        return false
      end

      result = fetched_object.id == object_id && fetched_object.status == object_status
      Rails.logger.info("[Yookassa Webhook] API object check: fetched_id=#{fetched_object.id}, fetched_status=#{fetched_object.status}, matches=#{result}")
      result
    rescue StandardError => e
      Rails.logger.info("[Yookassa Webhook] API object check failed: #{e.message}")
      false
    end

    def extract_object(payload)
      payload["object"] || payload.dig("data", "object")
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
