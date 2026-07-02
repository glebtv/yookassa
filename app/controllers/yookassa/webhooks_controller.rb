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
        log_missing_token(token, configured_token)
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

    def log_missing_token(token, configured_token)
      param_state = token.empty? ? "empty" : "present"
      configured_state = configured_token.empty? ? "empty" : "present"

      Rails.logger.info(
        "[Yookassa Webhook] Token validation failed: " \
        "param_token=#{param_state}, configured_token=#{configured_state}"
      )
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
      return false unless valid_payload_object?(object)

      object_id = object["id"].to_s
      object_status = object["status"].to_s
      return false unless valid_object_identity?(object_id, object_status)

      fetched_object = fetch_object_from_api(payload, object_id)
      return log_missing_api_object(object_id) unless fetched_object

      result = fetched_object.id == object_id && fetched_object.status == object_status
      log_api_object_match(fetched_object, result)
      result
    rescue StandardError => e
      Rails.logger.info("[Yookassa Webhook] API object check failed: #{e.message}")
      false
    end

    def valid_payload_object?(object)
      return true if object.is_a?(Hash)

      Rails.logger.info("[Yookassa Webhook] API object check failed: object is not a Hash")
      false
    end

    def valid_object_identity?(object_id, object_status)
      return true unless object_id.empty? || object_status.empty?

      Rails.logger.info("[Yookassa Webhook] API object check failed: object_id=#{object_id}, object_status=#{object_status}")
      false
    end

    def log_missing_api_object(object_id)
      Rails.logger.info("[Yookassa Webhook] API object check failed: could not fetch object #{object_id}")
      false
    end

    def log_api_object_match(fetched_object, result)
      Rails.logger.info(
        "[Yookassa Webhook] API object check: fetched_id=#{fetched_object.id}, " \
        "fetched_status=#{fetched_object.status}, matches=#{result}"
      )
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
