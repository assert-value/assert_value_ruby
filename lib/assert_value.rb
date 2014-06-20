# Copyright (c) 2010-2011 Pluron, Inc.

# make sure test/unit or minitest is loaded before assert_value
# once Ruby 1.8 support is removed, we can replace this code
# with .gemspec dependency on minitest
begin
    require 'minitest/unit'
rescue LoadError
    require 'test/unit'
end

# there're 3 types of test frameworks we support
# 1) test/unit from Ruby 1.8
# 2) old minitest 2.x-4.x, either bundled with Ruby 1.9 - 2.1 or installed via gem
# 3) new minitest 5.x from minitest gem (required for example by Rails 4.1)

if defined?(Minitest) and Minitest.const_defined?("VERSION") and Minitest::VERSION >= "5.0.0"
    ASSERT_VALUE_TEST_FRAMEWORK = :new_minitest
elsif defined?(MiniTest)
    ASSERT_VALUE_TEST_FRAMEWORK = :old_minitest
elsif defined?(Test)
    ASSERT_VALUE_TEST_FRAMEWORK = :test_unit
else
    raise LoadError.new("Require assert_value after 'test/unit' or 'minitest/autorun'")
end

require 'text_diff'
require 'pathname'

$assert_value_options = []

if ASSERT_VALUE_TEST_FRAMEWORK == :new_minitest
    # minitest options are handled by minitest/assert_value_plugin.rb that is required automatically

elsif ASSERT_VALUE_TEST_FRAMEWORK == :old_minitest and defined?(Test)
    # Test/Unit from Ruby 1.9 has a strict option parser, need to explicitly add options there.
    # 
    # Note, this works only for tests that use 'test/unit'. 'minitest/autorun' in old versions
    # is not powerful enough to accept custom options. This is fixed in minitest 5.0.
    module Test::Unit

        module AssertValueOption
            def setup_options(parser, options)
                super
                parser.on '--no-interactive', 'assert_value: non-interactive mode' do |flag|
                    $assert_value_options << "--no-interactive"
                end
                parser.on '--no-canonicalize', 'assert_value: turn off canonicalization' do |flag|
                    $assert_value_options << "--no-canonicalize"
                end
                parser.on '--autoaccept', 'assert_value: automatically accept new actual values' do |flag|
                    $assert_value_options << "--autoaccept"
                end
            end

            def non_options(files, options)
                super
            end
        end

        class Runner < MiniTest::Unit
            include Test::Unit::AssertValueOption
        end

    end

elsif ASSERT_VALUE_TEST_FRAMEWORK == :test_unit

    # In Ruby 1.8 additional test options are simply passed via ARGV
    #   ruby test.rb -- --foo
    $assert_value_options << "--no-interactive" if ARGV.include?("--no-interactive")
    $assert_value_options << "--no-canonicalize" if ARGV.include?("--no-canonicalize")
    $assert_value_options << "--autoaccept" if ARGV.include?("--autoaccept")

end


#Use this to raise internal error with a given message
#You can define your own method for your application
unless defined? internal_error
    def internal_error(message = 'internal error')
        raise message
    end
end


module AssertValueAssertion

    def file_offsets
      @@file_offsets ||= Hash.new { |hash, key| hash[key] = {} }
    end

    # assert_value: assert which checks that two strings (expected and actual) are same
    # and which can "magically" replace expected value with the actual in case
    # the new behavior (and new actual value) is correct
    #
    # == Usage ==
    #
    # Write this in the test source:
    #     assert_value something, <<-END
    #         foo
    #         bar
    #         zee
    #     END
    #
    # You can also use assert_value for blocks. Then you can assert block result or raised exception
    #    assert_value(<<-END) do
    #        Exception NoMethodError: undefined method `+' for nil:NilClass
    #    END
    #        # Code block starts here
    #        c = nil + 1
    #    end
    # 
    # Then run tests as usual:
    #    rake test:units
    #    ruby test/unit/foo_test.rb
    #    ...
    #
    # When assert_value fails, you'll be able to:
    # - review diff
    # - (optionally) accept new actual value (this modifies the test source file)
    #
    # Additional options for test runs:
    # --no-interactive skips all questions and just reports failures
    # --autoaccept prints diffs and automatically accepts all new actual values
    # --no-canonicalize turns off expected and actual value canonicalization (see below for details)
    #
    # Additional options can be passed during both single test file run and rake test run:
    #    In Ruby 1.8:
    #    ruby test/unit/foo_test.rb -- --autoaccept
    #    ruby test/unit/foo_test.rb -- --no-interactive
    #
    #    rake test TESTOPTS="-- --autoaccept"
    #    rake test:units TESTOPTS="-- --no-canonicalize --autoaccept"
    #
    #    In Ruby 1.9:
    #    ruby test/unit/foo_test.rb --autoaccept
    #    ruby test/unit/foo_test.rb --no-interactive
    #
    #    rake test TESTOPTS="--autoaccept"
    #    rake test:units TESTOPTS="--no-canonicalize --autoaccept"
    #
    #
    # == Canonicalization ==
    #
    # Before comparing expected and actual strings, assert_value canonicalizes both using these rules:
    # - indentation is ignored (except for indentation
    #   relative to the first line of the expected/actual string)
    # - ruby-style comments after "#" are ignored: 
    #   both whole-line and end-of-line comments are supported
    # - empty lines are ignored
    # - trailing whitespaces are ignored
    #
    # You can turn canonicalization off with --no-canonicalize option. This is useful
    # when you need to regenerate expected test strings.
    # To regenerate the whole test suite, run:
    #    In Ruby 1.8:
    #    rake test TESTOPTS="-- --no-canonicalize --autoaccept"
    #    In Ruby 1.9:
    #    rake test TESTOPTS="--no-canonicalize --autoaccept"
    #
    # Example of assert_value with comments:
    #  assert_value something, <<-END
    #      # some tree
    #      foo 1
    #        foo 1.1
    #        foo 1.2    # some node
    #      bar 2
    #        bar 2.1
    #  END
    #
    #
    #
    # == Umportant Usage Rules ==
    #
    # Restrictions:
    # - only END and EOS are supported as end of string sequence
    # - it's a requirement that you have <<-END at the same line as assert_value
    # - assert_value can't be within a block
    #
    # Storing expected output in files:
    # - assert_value something, :log => <path_to_file>
    # - path to file is relative to:
    #   - RAILS_ROOT (if that is defined)
    #   - current dir (if no RAILS_ROOT is defined)
    # - file doesn't have to exist, it will be created if necessary
    #
    # Misc:
    # - it's ok to have several assert_value's in the same test method, assert_value.
    #   correctly updates all assert_value's in the test file
    # - it's ok to omit expected string, like this:
    #       assert_value something
    #   in fact, this is the preferred way to create assert_value tests - you write empty
    #   assert_value, run tests and they will fill expected values for you automatically
    def assert_value(*args)
        if block_given?
            # rspec passes block to the expect() function, not to the matcher
            # so string substitution should work as if assert_value is called with a string
            mode = @rspec_matcher ? :scalar : :block
            expected = args[0]
            actual = ""
            begin
                actual = yield.to_s
            rescue Exception => e
                actual = "Exception #{e.class}: #{e.message}"
            end
        else
            mode = :scalar
            expected = args[1]
            actual = args[0]
        end

        if expected.nil?
            expected = ""
            change = :create_expected_string
        elsif expected.class == String
            change = :update_expected_string
        elsif expected.class == Hash
            raise ":log key is missing" unless expected.has_key? :log
            log_file = expected[:log]
            if defined? RAILS_ROOT
                log_file = File.expand_path(log_file, RAILS_ROOT)
            else
                log_file = File.expand_path(log_file, Dir.pwd)
            end
            expected = File.exists?(log_file) ? File.read(log_file) : ""
            change = :update_file_with_expected_string
        else
            internal_error("Invalid expected class #{excepted.class}")
        end

        # interactive mode is turned on by default, except when
        # - --no-interactive is given
        # - CIRCLECI is set (CircleCI captures test output, but doesn't interact with user)
        # - STDIN is not a terminal device (i.e. we can't ask any questions)
        interactive = !$assert_value_options.include?("--no-interactive") && !ENV["CIRCLECI"] && STDIN.tty?
        canonicalize = !$assert_value_options.include?("--no-canonicalize")
        autoaccept = $assert_value_options.include?("--autoaccept")

        is_same_canonicalized, is_same, diff_canonicalized, diff = compare_for_assert_value(expected, actual)

        if (canonicalize and !is_same_canonicalized) or (!canonicalize and !is_same)
            diff_to_report = canonicalize ? diff_canonicalized : diff
            if interactive
                # print method name and short backtrace
                soft_fail(diff_to_report)

                if autoaccept
                    accept = true
                else
                    print "Accept the new value: yes to all, no to all, yes, no? [Y/N/y/n] (y): "
                    STDOUT.flush
                    response = STDIN.gets.strip
                    accept = ["", "y", "Y"].include? response
                    $assert_value_options << "--autoaccept" if response == "Y"
                    $assert_value_options << "--no-interactive" if response == "N"
                end

                if accept
                    if [:create_expected_string, :update_expected_string].include? change
                        accept_string(actual, change, mode)
                    elsif change == :update_file_with_expected_string
                        accept_file(actual, log_file)
                    else
                        internal_error("Invalid change #{change}")
                    end
                end
            end
            if accept
                # when change is accepted, we should not report it as a failure because
                # we want the test method to continue executing (in case there're more
                # assert_value's in the method)
                succeed
            else
                fail(diff)
            end
        else
            succeed
        end
    end

    def be_same_value_as(expected = nil)
      BeSameValueAs.new(expected)
    end

private

    def succeed
        increment_assertion_count
        true
    end

    def increment_assertion_count
        return if @rspec_matcher or self.class.name =~ /RSpec/
        case ASSERT_VALUE_TEST_FRAMEWORK
            when :new_minitest then self.assertions += 1
            when :old_minitest then self._assertions += 1
            when :test_unit    then add_assertion
        end
    end

    def soft_fail(diff)
        if [:new_minitest, :old_minitest].include?(ASSERT_VALUE_TEST_FRAMEWORK)
            failure = MiniTest::Assertion.new(diff)
        else
            failure = Test::Unit::Failure.new(name, filter_backtrace(caller(0)), diff)
        end
        puts "\n#{failure}"
    end

    def fail(diff)
        increment_assertion_count
        if [:new_minitest, :old_minitest].include?(ASSERT_VALUE_TEST_FRAMEWORK)
            raise MiniTest::Assertion.new(diff)
        else
            raise Test::Unit::AssertionFailedError.new(diff)
        end
    end

    # actual - actual value of the scalar or result of the executed block
    # change - what to do with expected value (:create_expected_string or :update_expected_string)
    # mode   - describes signature of assert_value call by type of main argument (:block or :scalar)
    def accept_string(actual, change, mode)
        depth = @rspec_matcher ? 6 : 3
        file, method, line = get_caller_location(:depth => depth)

        # read source file, construct the new source, replacing everything
        # between "do" and "end" in assert_value's block
        # using File::expand_path here because "file" can be either
        # absolute path (when test is run with "rake test" runs)
        # or relative path (when test is run via ruby <path_to_test_file>)
        source = File.readlines(File::expand_path(file))

        # file may be changed by previous accepted assert_value's, adjust line numbers
        offset = file_offsets[file].keys.inject(0) do |sum, i|
            line.to_i >= i ? sum + file_offsets[file][i] : sum
        end

        expected_text_end_line = expected_text_start_line = line.to_i + offset
        if change == :update_expected_string
            #search for the end of expected value in code
            expected_text_end_line += 1 while !["END", "EOS"].include?(source[expected_text_end_line].strip)
        elsif change == :create_expected_string
            # The is no expected value yet. expected_text_end_line is unknown
        else
            internal_error("Invalid change #{change}")
        end

        expected_length = expected_text_end_line - expected_text_start_line

        # indentation is the indentation of assert_value call + 4
        indentation = source[expected_text_start_line-1] =~ /^(\s+)/ ? $1.length : 0
        indentation += 4

        if change == :create_expected_string 
            if mode == :scalar
                # add second argument to assert_value if it's omitted
                comma = "," unless @rspec_matcher
                source[expected_text_start_line-1] = "#{source[expected_text_start_line-1].chop}#{comma} <<-END\n"
            elsif mode == :block
                # add expected value as argument to assert_value before block call
                source[expected_text_start_line-1] = source[expected_text_start_line-1].sub(/assert_value(\(.*?\))*/, "assert_value(<<-END)")
            else
                internal_error("Invalid mode #{mode}")
            end
        end
        source = source[0, expected_text_start_line] +
            actual.split("\n").map { |l| "#{" "*(indentation)}#{l}\n"} +
            (change == :create_expected_string ? ["#{" "*(indentation-4)}END\n"] : [])+
            source[expected_text_end_line, source.length]

        # recalculate line number adjustments
        actual_length = actual.split("\n").length
        actual_length += 1 if change == :create_expected_string # END marker after expected value
        file_offsets[file][line.to_i] = actual_length - expected_length

        source_file = File.open(file, "w+")
        source_file.write(source.join(''))
        source_file.fsync
        source_file.close
    end

    def accept_file(actual, log_file)
        log = File.open(log_file, "w+")
        log.write(actual)
        log.fsync
        log.close
    end

    def compare_for_assert_value(expected_verbatim, actual_verbatim)
        expected_canonicalized, expected = canonicalize_for_assert_value(expected_verbatim)
        actual_canonicalized, actual = canonicalize_for_assert_value(actual_verbatim)
        diff_canonicalized = AssertValue::TextDiff.array_diff(expected_canonicalized, actual_canonicalized)
        diff = AssertValue::TextDiff.array_diff(expected, actual)
        [expected_canonicalized == actual_canonicalized, expected == actual, diff_canonicalized, diff]
    end

    def canonicalize_for_assert_value(text)
        # make array of lines out of the text
        result = text.split("\n")

        # ignore leading newlines if any (trailing will be automatically ignored by split())
        result.delete_at(0) if result[0] == ""

        indentation = $1.length if result[0] and result[0] =~ /^(\s+)/

        result.map! do |line|
            # ignore indentation: we assume that the first line defines indentation
            line.gsub!(/^\s{#{indentation}}/, '') if indentation
            # ignore trailing spaces
            line.gsub(/\s*$/, '')
        end

        # ignore comments
        result_canonicalized= result.map do |line|
            line.gsub(/\s*(#.*)?$/, '')
        end
        # ignore blank lines (usually they are lines with comments only)
        result_canonicalized.delete_if { |line| line.nil? or line.empty? }

        [result_canonicalized, result]
    end

    def get_caller_location(options = {:depth => 2})
        caller_method = caller(options[:depth])[0]

        #Sample output is:
        #either full path when run as "rake test"
        #   /home/user/assert_value/test/unit/assure_test.rb:9:in `test_assure
        #or relative path when run as ruby test/unit/assure_test.rb
        #   test/unit/assure_test.rb:9:in `test_assure
        caller_method =~ /([^:]+):([0-9]+):in `(.+)'/
        file = $1
        line = $2
        method = $3
        [file, method, line]
    end

end

if ASSERT_VALUE_TEST_FRAMEWORK == :new_minitest
    class Minitest::Test
        include AssertValueAssertion
    end
elsif ASSERT_VALUE_TEST_FRAMEWORK == :old_minitest
    class MiniTest::Unit::TestCase
        include AssertValueAssertion
    end
elsif ASSERT_VALUE_TEST_FRAMEWORK == :test_unit
    class Test::Unit::TestCase
        include AssertValueAssertion
    end
end

# RSpec matcher for assert_value
class BeSameValueAs
    include AssertValueAssertion

    def initialize(expected)
        @expected = expected
        @rspec_matcher = true
    end

    def matches?(target)
      if target.is_a? Proc
          assert_value @expected, &target
      else
          assert_value target, @expected
      end
    end

    def failure_message_for_should
        "expected to be the same"
    end

    def failure_message_for_should_not
        "expected not to be the same"
    end
end


if defined?(RSpec)
    RSpec.configure do |c|
        c.include AssertValueAssertion
    end
end
