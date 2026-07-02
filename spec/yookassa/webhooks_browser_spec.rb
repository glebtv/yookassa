# frozen_string_literal: true

RSpec.describe "Yookassa webhook endpoint", :rails, :browser do
  include Capybara::DSL

  around do |example|
    previous_driver = Capybara.current_driver
    Capybara.current_driver = :cuprite
    example.run
    Capybara.current_driver = previous_driver
  end

  before do
    Yookassa.config.webhook_allowed_ips = ["127.0.0.1"]

    payments_client = instance_double(Yookassa::Payments)
    allow(Yookassa).to receive(:payments).and_return(payments_client)
    allow(payments_client).to receive(:find).with(payment_id: "browser-payment")
                                            .and_return(instance_double(Yookassa::Entity::Payment, id: "browser-payment", status: "succeeded"))
  end

  it "accepts browser-submitted webhook request" do
    visit "/browser"

    click_button "Send webhook"

    expect(page).to have_text("200")
  end
end
