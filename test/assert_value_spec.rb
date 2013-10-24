require 'assert_value'

describe "Assert Value" do

  it "compares with value in file" do
    assert_value("foo", :log => 'test/logs/assert_value_with_files.log.ref')
    expect(assert_value("foo", :log => 'test/logs/assert_value_with_files.log.ref')).to eq(true)
  end

  it "compares with value inlined in source file" do
    assert_value "foo", <<-END
        foo
    END

    expect(
      assert_value "foo", <<-END
          foo
      END
    ).to eq(true)

    expect(assert_value(<<-END) do
        foo
    END
      "foo"
    end).to eq(true)
  end

end
