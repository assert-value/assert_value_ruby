# Copyright (c) 2011 Pluron, Inc.

require 'test/unit'
require 'assert_same'

class AssertSameTest < Test::Unit::TestCase

    def test_basic_assert_same
        assert_same "foo", <<-END
            foo
        END
    end

    def test_assert_same_with_files
        assert_same "foo", :log => 'test/logs/assert_same_with_files.log.ref'
    end

    def test_assert_same_empty_string
        # These two calls are the same
        assert_same ""
        assert_same "", <<-END
        END
    end

    def test_assert_same_exception
        assert_same(<<-END) do
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
            nil + 1
        end
    end

    def test_assert_same_for_block_value
        assert_same(<<-END) do
            All Ok!
        END
            a = "All Ok!"
        end
    end

    def test_assert_same_exception_with_files
        assert_same(:log => 'test/logs/assert_same_exception_with_files.log.ref') do
            nil + 1
        end
    end

    def test_assert_same_block_alternative_syntax
        assert_same(<<-END) {
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
            nil + 1
        }
    end

    def test_assert_same_block_alternative_syntax_one_liner
        assert_same(<<-END) { nil + 1 }
            Exception NoMethodError: undefined method `+' for nil:NilClass
        END
    end

    def test_assert_same_for_empty_block
        # These calls are the same
        assert_same { }

        assert_same do end

        assert_same(<<-END) { }
        END

        assert_same(<<-END) do end
        END
    end

    def test_assert_same_for_nil_block_result
        # These calls are the same
        assert_same { nil }

        assert_same do nil end

        assert_same(<<-END) { nil }
        END

        assert_same(<<-END) do nil end
        END
    end

end

if RUBY_VERSION >= "1.9.0"

class AssertSameMiniTest < MiniTest::Unit::TestCase

    def test_basic_assert_same
        assert_same "foo", <<-END
            foo
        END
    end

end

end
