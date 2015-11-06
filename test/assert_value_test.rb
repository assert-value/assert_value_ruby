# Copyright (c) 2011-2015 Pluron, Inc.

begin
    require 'minitest' # Minitest 5.x
rescue LoadError
    begin
        require 'minitest/unit' # old Minitest
    rescue LoadError
        begin
            require 'test/unit' # Test::Unit
        rescue LoadError
            # RSpec only
        end
    end
end
require 'assert_value'

case ASSERT_VALUE_TEST_FRAMEWORK
    when :new_minitest then
        require 'minitest/autorun'
        test_case_class = Minitest::Test
    when :old_minitest then
        require 'minitest/autorun'
        test_case_class = MiniTest::Unit::TestCase
    when :test_unit then
        test_case_class = Test::Unit::TestCase
    when :rspec_only then
        raise "This test case requires either Minitest or Test::Unit"
    else
        raise "Unknown test framework"
end

class AssertValueTest < test_case_class

    def test_basic_assert_value
        assert_value "foo", <<-END
            foo
        END
    end

    def test_assert_value_with_files
        assert_value "foo", :log => 'test/logs/assert_value_with_files.log.ref'
    end

    def test_assert_value_empty_string
        # These two calls are the same
        assert_value ""
        assert_value "", <<-END
        END
    end

    def test_assert_value_exception
        assert_value(<<-END) do
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
            nil + 1
        end
    end

    def test_assert_value_for_block_value
        assert_value(<<-END) do
            All Ok!
        END
            a = "All Ok!"
        end
    end

    def test_assert_value_exception_with_files
        assert_value(:log => 'test/logs/assert_value_exception_with_files.log.ref') do
            nil + 1
        end
    end

    def test_assert_value_block_alternative_syntax
        assert_value(<<-END) {
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
            nil + 1
        }
    end

    def test_assert_value_block_alternative_syntax_one_liner
        assert_value(<<-END) { nil + 1 }
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
    end

    def test_assert_value_for_empty_block
        # These calls are the same
        assert_value { }

        assert_value do end

        assert_value(<<-END) { }
        END

        assert_value(<<-END) do end
        END
    end

    def test_assert_value_for_nil_block_result
        # These calls are the same
        assert_value { nil }

        assert_value do nil end

        assert_value(<<-END) { nil }
        END

        assert_value(<<-END) do nil end
        END
    end

end
