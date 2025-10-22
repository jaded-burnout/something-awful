require "spec_helper"
require "models/record"

RSpec.describe Record do
  let(:test_record_class) do
    Class.new(Record) do
      attributes %I[
        test
        testing
      ]
    end
  end

  it "assigns permitted attributes" do
    record = test_record_class.new(test: "123")
    expect(record.test).to eq("123")
    expect(record.testing).to eq(nil)
    expect(record.respond_to?(:nonattribute)).to eq(false)

    record = test_record_class.new(test: "123", testing: "567")
    expect(record.test).to eq("123")
    expect(record.testing).to eq("567")

    record = test_record_class.new(test: "123", nonattribute: "567")
    expect(record.test).to eq("123")
    expect(record.respond_to?(:nonattribute)).to eq(false)
  end
end
