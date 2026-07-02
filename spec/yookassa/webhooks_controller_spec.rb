# frozen_string_literal: true

RSpec.describe Yookassa::WebhooksController do
  def app
    YookassaSpecApp
  end

  let(:payload_hash) do
    {
      "event" => "payment.succeeded",
      "object" => {
        "id" => "payment-1",
        "status" => "succeeded"
      }
    }
  end
  let(:payload) { JSON.generate(payload_hash) }
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "REMOTE_ADDR" => remote_addr
    }
  end
  let(:remote_addr) { "185.71.76.1" }

  describe "POST /yookassa/webhooks/:token", :rails do
    it "accepts webhook when token, remote_ip, and API re-fetch checks pass" do
      payments_client = instance_double(Yookassa::Payments)
      allow(Yookassa).to receive(:payments).and_return(payments_client)
      allow(payments_client).to receive(:find).with(payment_id: "payment-1")
                                              .and_return(instance_double(Yookassa::Entity::Payment, id: "payment-1", status: "succeeded"))

      post "/yookassa/webhooks/secret-token", payload, headers

      expect(last_response.status).to eq(200)
    end

    it "rejects webhook when token is invalid" do
      payments_client = instance_double(Yookassa::Payments)
      allow(Yookassa).to receive(:payments).and_return(payments_client)
      allow(payments_client).to receive(:find).with(payment_id: "payment-1")
                                              .and_return(instance_double(Yookassa::Entity::Payment, id: "payment-1", status: "succeeded"))

      post "/yookassa/webhooks/wrong-token", payload, headers

      expect(last_response.status).to eq(401)
    end

    it "rejects webhook when source remote_ip is outside allowlist" do
      payments_client = instance_double(Yookassa::Payments)
      allow(Yookassa).to receive(:payments).and_return(payments_client)
      allow(payments_client).to receive(:find).with(payment_id: "payment-1")
                                              .and_return(instance_double(Yookassa::Entity::Payment, id: "payment-1", status: "succeeded"))

      post "/yookassa/webhooks/secret-token", payload, headers.merge("REMOTE_ADDR" => "203.0.113.10")

      expect(last_response.status).to eq(401)
    end

    it "rejects webhook when fetched object differs by status" do
      payments_client = instance_double(Yookassa::Payments)
      allow(Yookassa).to receive(:payments).and_return(payments_client)
      allow(payments_client).to receive(:find).with(payment_id: "payment-1")
                                              .and_return(instance_double(Yookassa::Entity::Payment, id: "payment-1", status: "pending"))

      post "/yookassa/webhooks/secret-token", payload, headers

      expect(last_response.status).to eq(401)
    end
  end

  describe "logging", :rails do
    it "logs auth result when webhook authentication fails" do
      controller = described_class.new

      allow(controller).to receive(:token_valid?).and_return(true)
      allow(controller).to receive(:source_ip_allowed?).and_return(false)
      allow(controller).to receive(:payload_matches_api_object?).and_return(true)
      allow(controller).to receive(:request).and_return(instance_double(ActionDispatch::Request, remote_ip: "192.168.0.10"))

      expect(Rails.logger).to receive(:info).with(include("Auth failed: token=true, ip=false, api=true"))

      expect(controller.send(:authentic_webhook?, {})).to eq(false)
    end
  end

  describe "IP source check", :rails do
    it "uses request.remote_ip" do
      controller = described_class.new
      request = instance_double(ActionDispatch::Request)

      allow(request).to receive(:remote_ip).and_return("185.71.76.5")
      allow(request).to receive(:ip).and_raise("request.ip should not be used")
      allow(controller).to receive(:request).and_return(request)

      expect(controller.send(:source_ip_allowed?)).to eq(true)
    end
  end

  describe "controller inheritance", :rails do
    it "allows app controller override via inheritance" do
      payments_client = instance_double(Yookassa::Payments)
      allow(Yookassa).to receive(:payments).and_return(payments_client)
      allow(payments_client).to receive(:find).with(payment_id: "payment-1")
                                              .and_return(instance_double(Yookassa::Entity::Payment, id: "payment-1", status: "succeeded"))

      post "/custom-yookassa/secret-token", payload, headers

      expect(last_response.status).to eq(200)
      expect(YookassaSpecCustomWebhooksController.last_payload).to eq(payload_hash)
    end
  end
end
