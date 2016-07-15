# assert_value

[![Gem Version](https://badge.fury.io/rb/assert_value.svg)](https://badge.fury.io/rb/assert_value)
[![Build Status](https://travis-ci.org/acunote/assert_value.svg?branch=master)](https://travis-ci.org/acunote/assert_value)

Checks that two values are same and "magically" replaces expected value
with the actual in case the new behavior (and new actual value) is correct.
Support two kind of arguments: string and code block.

This check works with both Test/Unit and RSpec. See documentation and examples below:

## Testing String Values

It is better to start with no expected value

    assert_value "foo"

Then run tests as usual with "rake test". As a result you will see
diff between expected and actual values:

    Failure:
    @@ -1,0, +1,1 @@
    +foo
    Accept the new value: yes to all, no to all, yes, no? [Y/N/y/n] (y):

If you accept the new value your test will be automatically modified to

    assert_value "foo", <<-END
        foo
    END

## Testing Block Values

assert_value can take code block as an argument. If executed block raises exception then
exception message is returned as actual value:

    assert_value do
        nil+1
    end

Run tests

    Failure:
    @@ -1,0, +1,1 @@
    +Exception NoMethodError: undefined method `+' for nil:NilClass
    Accept the new value: yes to all, no to all, yes, no? [Y/N/y/n] (y): 

After the new value is accepted you get

    assert_value(<<-END) do
        Exception NoMethodError: undefined method `+' for nil:NilClass
    END
        nil + 1
    end

## Testing Values Stored in Files

Sometimes test string is too large to be inlined into the test source. Put it into the file instead:

    assert_value "foo", log: 'test/log/reference.txt'

## Additional Test/Unit Options:

    --no-interactive skips all questions and just reports failures
    --autoaccept prints diffs and automatically accepts all new actual values
    --no-canonicalize turns off expected and actual value canonicalization (see below for details)

Additional options can be passed during both single test file run and rake test run:

In Ruby 1.8:

    ruby test/unit/foo_test.rb -- --autoaccept
    rake test TESTOPTS="-- --autoaccept"

In Ruby 1.9:

    ruby test/unit/foo_test.rb --autoaccept
    rake test TESTOPTS="--autoaccept"

## RSpec

In specs you can either call assert_value directly or use "be_same_value_as" matcher:

    describe "spec with be_same_value_as matcher" do
        it "compares with inline value" do
            expect("foo").to be_same_value_as <<-END
                foo
            END
        end

        it "compares with inline block" do
            expect { "foo" }.to be_same_value_as <<-END
                foo
            END
        end

        it "compares with value in file" do
            expect("foo").to be_same_value_as(:log => 'test/logs/assert_value_with_files.log.ref')
        end
    end


## Canonicalization:

Before comparing expected and actual strings, assert_value canonicalizes both using these rules:

- indentation is ignored (except for indentation  relative to the first line of the expected/actual string)
- ruby-style comments after "#" are ignored
- empty lines are ignored
- trailing whitespaces are ignored

You can turn canonicalization off with --no-canonicalize option. This is useful
when you need to regenerate expected test strings.
To regenerate the whole test suite, run:

In Ruby 1.8:

    rake test TESTOPTS="-- --no-canonicalize --autoaccept"

In Ruby 1.9:

    rake test TESTOPTS="--no-canonicalize --autoaccept"


## Changelog

- 1.5: Improve support for various testing frameworks and Ruby versions:
       Ruby 2.2.2, 2.2.3, RSpec 2.x, 3.x, Test::Unit 2.x, 3.x, Minitest 4.x, 5.x
- 1.4: Fix RSpec support
- 1.3: Improve support for various testing frameworks, fix assertion counters
- 1.2: Rails 4.1 and minitest gem support
- 1.1: RSpec support
- 1.0: Rename to assert_value
- 0.7: Support Ruby 1.9's MiniTest
- 0.6: Support test execution on Mac
- 0.5: Support code blocks to assert_same
- 0.4: Added support for code blocks as argument
- 0.3: Ruby 1.9 is supported
- 0.2: Make assert_same useful as a standalone gem. Bugfixes
- 0.1: Initial release
