# Copyright (c) 2010 Pluron, Inc.

class ActiveSupport::TestCase

    #Hash[filename][line_number] = offset
    #For each line in the original file we store its offset (+N or -N lines)
    #relative to the actual file
    @@file_offsets = Hash.new { |hash, key| hash[key] = {} }

    #Usage:
    #In the test source:
    #    assert_same something, <<-END
    #        foo
    #        bar
    #        zee
    #    END
    #
    #Runing tests as usual will report a failure (if any) and show a diff.
    #Running tests with --interactive will let you review diffs and accept new actual values
    #as expected (modifying the test files).
    #Running tests with --interactive --accept-new-values will print out diffs 
    #and accept all new actual values.
    #Examples:
    #    ruby test/unit/foo_test.rb -- --interactive
    #    ruby test/unit/foo_test.rb -- --interactive --accept-new-values
    #    rake test TESTOPTS="-- --interactive --accept-new-values"
    #    rake test:units TESTOPTS="-- --interactive --accept-new-values"
    #
    #
    #Note:
    #- assert_same ignores indentation, so you don't have to start your "expected" string
    #  from the first position in the line (see example above)
    #- but it skips only the indentation of the first line in the "expected" string, so
    #  you still can use indentation like this:
    #  assert_same something, <<-END
    #      foo 1
    #        foo 1.1
    #        foo 1.2
    #      bar 2
    #        bar 2.1
    #  END
    #- only END and EOS are supported as end of string sequence
    #- it's a requirement that you have <<-END at the same line as assert_same
    #- it's ok to have several assert_same's in the same test method, assert_same.
    #  correctly updates all assert_same's in the test file
    #- it's ok to omit expected string, like this:
    #  assert_same something
    #  in fact, this is the preferred way to create assert_same tests - you write empty
    #  assert_same, tests in interactive mode will autofill expected value automatically,
    #  and then you just commit the test
    def assert_same(actual, expected = :autofill_expected_value)
        if expected.class == String
            expected ||= ""
            mode = :expecting_string
        elsif expected == :autofill_expected_value
            expected = ""
            mode = :autofill_expected_value
        elsif expected.class == Hash
            assure(expected.has_key? :log)
            mode = :expecting_file
            log_file = File.expand_path(expected[:log], RAILS_ROOT)
            expected = File.read(log_file)
        else
            internal_error("Incorrect expected argument for assert_same. It must be either String or Hash.")
        end

        is_same_canonicalized, is_same, diff = compare_for_assert_same(expected, actual)
        if !is_same_canonicalized or (!is_same and ARGV.include?("--refresh"))
            if ARGV.include? "--interactive" or ARGV.include?("--refresh")
                # print method name and short backtrace
                failure = Test::Unit::Failure.new(name, filter_backtrace(caller(0)), diff)
                puts "\n#{failure}"

                if ARGV.include? "--accept-new-values" or ARGV.include?("--refresh") or mode == :autofill_expected_value
                    accept = true
                else
                    print "Accept the new value (Y/n)?: "
                    STDOUT.flush
                    accept = ["", "Y"].include? STDIN.gets.strip.upcase
                end

                if accept
                    if [:expecting_string, :autofill_expected_value].include? mode
                        accept_string(actual, mode)
                    elsif mode == :expecting_file
                        accept_file(actual, log_file)
                    end
                end
            end
            if accept
                # when change is accepted, we should not report it as a failure because
                # we want the test method to continue executing (in case there're more
                # assert_same's in the method)
                add_assertion
            else
                raise Test::Unit::AssertionFailedError.new(diff)
            end
        else
            add_assertion
        end
    end

    def accept_string(actual, mode)
        file, method, line = get_caller_location(:depth => 3)

        # read source file, construct the new source, replacing everything
        # between "do" and "end" in assert_same's block
        source = File.readlines(RAILS_ROOT + "/" + file)

        # file may be changed by previous accepted assert_same's, adjust line numbers
        offset = @@file_offsets[file].keys.inject(0) do |sum, i|
            line.to_i >= i ? sum + @@file_offsets[file][i] : sum
        end

        expected_text_end_line = expected_text_start_line = line.to_i + offset
        unless mode == :autofill_expected_value
            #if we're autofilling the value, END/EOS marker will not exist
            #(second arg to assert_same is omitted)
            #else we search for it
            expected_text_end_line += 1 while !["END", "EOS"].include?(source[expected_text_end_line].strip)
        end

        expected_length = expected_text_end_line - expected_text_start_line

        # indentation is the indentation of assert_same call + 4
        indentation = source[expected_text_start_line-1] =~ /^(\s+)/ ? $1.length : 0
        indentation += 4

        if mode == :autofill_expected_value
            # add second argument to assert_same if it's omitted
            source[expected_text_start_line-1] = "#{source[expected_text_start_line-1].chop}, <<-END\n"
        end
        source = source[0, expected_text_start_line] +
            actual.split("\n").map { |l| "#{" "*(indentation)}#{l}\n"} +
            (mode == :autofill_expected_value ? ["#{" "*(indentation-4)}END\n"] : [])+
            source[expected_text_end_line, source.length]

        # recalculate line number adjustments
        actual_length = actual.split("\n").length
        actual_length += 1 if mode == :autofill_expected_value  # END marker after actual value
        @@file_offsets[file][line.to_i] = actual_length - expected_length

        source_file = File.open(RAILS_ROOT + "/" + file, "w+")
        source_file.write(source)
        source_file.fsync
        source_file.close
    end

    def accept_file(actual, log_file)
        log = File.open(log_file, "w+")
        log.write(actual)
        log.fsync
        log.close
    end

    def compare_for_assert_same(expected_verbatim, actual_verbatim)
        expected_canonicalized, expected = canonicalize_for_assert_same(expected_verbatim)
        actual_canonicalized, actual = canonicalize_for_assert_same(actual_verbatim)
        diff = NimbleTextDiff.array_diff(expected_canonicalized, actual_canonicalized)
        [expected_canonicalized == actual_canonicalized, expected == actual, diff]
    end

    def canonicalize_for_assert_same(text)
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
        result_canonicalized.delete_if { |line| line.blank? }

        [result_canonicalized, result]
    end

end
