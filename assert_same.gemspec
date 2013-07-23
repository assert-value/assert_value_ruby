require 'rubygems'

SPEC = Gem::Specification.new do |s|
    s.name        = "assert_same"
    s.version     = "0.4"
    s.author      = "Pluron, Inc."
    s.email       = "support@pluron.com"
    s.homepage    = "http://github.com/acunote/assert_same"
    s.platform    = Gem::Platform::RUBY
    s.description = "assert_same assertion"
    s.summary     = "Assert which checks that two strings (expected and actual) are same and which can magically replace expected value with the actual in case the new behavior (and new actual value) is correct"

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- test/*`.split("\n")

    s.require_path  = "lib"
    s.has_rdoc      = true
end
