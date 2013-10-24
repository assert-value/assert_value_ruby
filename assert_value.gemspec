require 'rubygems'

SPEC = Gem::Specification.new do |s|
    s.name        = "assert_value"
    s.version     = "1.0"
    s.author      = "Pluron, Inc."
    s.email       = "support@pluron.com"
    s.homepage    = "http://github.com/acunote/assert_value"
    s.platform    = Gem::Platform::RUBY
    s.license     = 'MIT'
    s.description = "assert_value assertion"
    s.summary     = "Assert that checks that two values (strings, expected and actual) are same and which can magically replace expected value with the actual in case the new behavior (and new actual value) is correct"

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- test/*`.split("\n")

    s.require_path  = "lib"
    s.has_rdoc      = true
end
