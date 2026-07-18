# frozen_string_literal: true

RSpec.describe Yookassa::Entity::Product do
  let(:attributes) do
    {
      description: "Fuel",
      quantity: 1,
      amount: { value: 100, currency: "RUB" },
      vat_code: 1
    }
  end

  it "defines excise as an optional numeric attribute" do
    expect(described_class.new(**attributes, excise: "12.34").excise).to eq(12.34)
    expect(described_class.new(**attributes).excise).to be_nil
  end
end
