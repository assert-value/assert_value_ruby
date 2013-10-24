require 'assert_value'

RSpec.configure do |c|
    c.include AssertValueAssertion
end

describe "Assert Value" do

  it "compares with value in file" do
    expect(assert_value("foo", :log => 'test/logs/assert_value_with_files.log.ref')).to eq(true)
  end

  it "compares with value inlined in source file" do
    assert_value "foo", <<-END
        foo
    END
  end

end