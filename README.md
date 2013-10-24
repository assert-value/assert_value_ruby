assert_same
===========

Checks that two strings are same and "magically" replace expected value 
with the actual in case the new behavior (and new actual value) is correct.
Support two kind of arguments: string and code block.

String Example:
---------------

It is better to start with no expected value

    assert_same "foo"

Then run tests as usual with "rake test". As a result you will see
diff between expected and actual values:

    Failure:
    @@ -1,0, +1,1 @@
    +foo
    Accept the new value: yes to all, no to all, yes, no? [Y/N/y/n] (y):

If you accept the new value your test will be automatically modified to

    assert_same "foo", <<-END
        foo
    END

Block Example:
--------------

assert_same supports code block as argument. If executed block raise exception
exception message is returned as actual value:

    assert_same do
        nil+1
    end

Run tests

    Failure:
    @@ -1,0, +1,1 @@
    +Exception NoMethodError: undefined method `+' for nil:NilClass
    Accept the new value: yes to all, no to all, yes, no? [Y/N/y/n] (y): 

After new value is accepted

    assert_same(<<-END) do
        Exception NoMethodError: undefined method `+' for nil:NilClass
    END
        nil + 1
    end

Options:
--------

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

Canonicalization:
-----------------

Before comparing expected and actual strings, assert_same canonicalizes both using these rules:

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


Changelog
---------
- 0.7: Support Ruby 1.9's MiniTest
- 0.6: Support test execution on Mac
- 0.5: Support code blocks to assert_same
- 0.4: Added support for code blocks as argument
- 0.3: Ruby 1.9 is supported
- 0.2: Make assert_same useful as a standalone gem. Bugfixes
- 0.1: Initial release
