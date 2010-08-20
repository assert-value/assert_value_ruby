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
    #- it's ok to leave expected string empty, like this:
    #  assert_same something, <<-END
    #  END
    #  in fact, this is the preferred way to create such tests - you write empty.
    #  assert_same and then accept the actual value as expected and commit
    def assert_same(actual, expected)
        expected ||= ""

        file, method, line = get_caller_location

        is_same, is_same_with_comments, diff = compare_for_assert_same(expected, actual)
        if !is_same or (!is_same_with_comments and ARGV.include?("--refresh"))
            if ARGV.include? "--interactive" or ARGV.include?("--refresh")
                # print method name and short backtrace
                failure = Test::Unit::Failure.new(name, filter_backtrace(caller(0)), diff)
                puts "\n#{failure}"

                if ARGV.include? "--accept-new-values" or ARGV.include?("--refresh")
                    accept = true
                else
                    print "Accept the new value (Y/n)?: "
                    STDOUT.flush
                    accept = ["", "Y"].include? STDIN.gets.strip.upcase
                end

                if accept
                    # read source file, construct the new source, replacing everything
                    # between "do" and "end" in assert_same's block
                    source = File.readlines(RAILS_ROOT + "/" + file)

                    # file may be changed by previous accepted assert_same's, adjust line numbers
                    offset = @@file_offsets[file].keys.inject(0) do |sum, i|
                        puts "checking offset. line #{line}. stored_offset for #{i} is #{@@file_offsets[file][i]}"
                        line.to_i >= i ? sum + @@file_offsets[file][i] : sum
                    end
                    puts "line #{line.to_i} offset #{offset}"

                    expected_text_end_line = expected_text_start_line = line.to_i + offset
                    expected_text_end_line += 1 while !["END", "EOS"].include?(source[expected_text_end_line].strip)

                    expected_length = expected_text_end_line - expected_text_start_line

                    # indentation is the indentation of assert_same call + 4
                    indentation = source[expected_text_start_line-1] =~ /^(\s+)/ ? $1.length : 0
                    indentation += 4

                    source = source[0, expected_text_start_line] +
                        actual.split("\n").map { |l| "#{" "*(indentation)}#{l}\n"} +
                        source[expected_text_end_line, source.length]

                    # recalculate line number adjustments
                    @@file_offsets[file][line.to_i] = actual.split("\n").length - expected_length

                    source_file = File.open(RAILS_ROOT + "/" + file, "w+")
                    source_file.write(source)
                    source_file.fsync
                    source_file.close
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

    def compare_for_assert_same(expected_verbatim, actual_verbatim)
        expected, expected_without_comments = canonicalize_for_assert_same(expected_verbatim)
        actual, actual_without_comments = canonicalize_for_assert_same(actual_verbatim)
        diff = NimbleTextDiff.array_diff(expected_without_comments, actual_without_comments)
        [expected_without_comments == actual_without_comments, expected == actual, diff]
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
        result_without_comments = result.map do |line|
            line.gsub(/\s*(#.*)?$/, '')
        end

        [result, result_without_comments]
    end

end
