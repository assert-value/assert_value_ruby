module Minitest
    def self.plugin_assert_value_options(opts, options)
        opts.on '--no-interactive', 'assert_value: non-interactive mode' do |flag|
            $assert_value_options << "--no-interactive"
        end
        opts.on '--no-canonicalize', 'assert_value: turn off canonicalization' do |flag|
            $assert_value_options << "--no-canonicalize"
        end
        opts.on '--autoaccept', 'assert_value: automatically accept new actual values' do |flag|
            $assert_value_options << "--autoaccept"
        end
    end
end
