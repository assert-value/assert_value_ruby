require 'assert_value'

describe "Assert Value" do

    describe "true rspec blessed way" do
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

    describe "test/unit way is also supported" do
        it "compares with inline value" do
            assert_value "foo", <<-END
                foo
            END
        end

        it "compares with inline block" do
            assert_value(<<-END) do
                foo
            END
                "foo"
            end
        end

        it "compares with value in file" do
            assert_value("foo", :log => 'test/logs/assert_value_with_files.log.ref')
        end
    end

end
