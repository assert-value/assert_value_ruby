# Copyright (c) 2011 Pluron, Inc.

require 'assert_value'
require 'test/unit'

class AssertValueTest < Test::Unit::TestCase

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

if RUBY_VERSION >= "1.9.0"

class AssertValueMiniTest < Test::Unit::TestCase

    def test_basic_assert_value
        assert_value "foo", <<-END
            foo
        END
    end

end

end
