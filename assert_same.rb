# Copyright (c) 2010 Pluron, Inc.

class ActiveSupport::TestCase

    @@file_offsets = Hash.new { |hash, key| hash[key] = 0 }

    def assert_same(actual, expected)
        expected ||= ""

        file, method, line = get_caller_location

        is_same, diff = compare_for_assert_same(expected, actual)
        if !is_same
            if ARGV.include? "--interactive"
                # print method name and short backtrace
                failure = Test::Unit::Failure.new(name, filter_backtrace(caller(0)), diff)
                puts "\n#{failure}"

                if ARGV.include? "--accept-new-values"
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
                    expected_text_end_line = expected_text_start_line = line.to_i + @@file_offsets[file]
                    expected_text_end_line += 1 while !["END", "EOS"].include?(source[expected_text_end_line].strip)

                    puts expected_text_start_line
                    puts expected_text_end_line
                    expected_length = expected_text_end_line - expected_text_start_line

                    # indentation is the indentation of assert_same call + 4
                    indentation = source[expected_text_start_line-1] =~ /^(\s+)/ ? $1.length : 0
                    indentation += 4

                    source = source[0, expected_text_start_line] +
                        actual.split("\n").map { |line| "#{" "*(indentation)}#{line}\n"} +
                        source[expected_text_end_line, source.length]

                    # recalculate line number adjustments
                    @@file_offsets[file] += actual.split("\n").length - expected_length

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
        expected = canonicalize_for_assert_same(expected_verbatim)
        actual = canonicalize_for_assert_same(actual_verbatim)
        diff = NimbleTextDiff.array_diff(expected, actual)
        [expected == actual, diff]
    end

    def canonicalize_for_assert_same(text)
        # make array of lines out of the text
        result = text.split("\n")

        # ignore leading newlines if any (trailing will be automatically ignored by split())
        result.delete_at(0) if result[0] == ""

        # ignore indentation: we assume that the first line defines indentation
        indentation = $1.length if result[0] and result[0] =~ /^(\s+)/
        result.map! {|line| line.gsub(/^\s{#{indentation}}/, '') } if indentation

        result
    end

end
