require 'assert_value'

RSpec.configure do |c|
    c.include AssertValueAssertion
end

describe "Assert Value" do

  it "compares with log in files" do
    expect(assert_value("foo", :log => 'test/logs/assert_value_with_files.log.ref')).to eq(true)
  end

end
