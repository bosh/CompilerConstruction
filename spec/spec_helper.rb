# encoding: utf-8

require "rubygems"
require 'test/unit'
require "spec"
$LOAD_PATH << File.expand_path(File.join('..', 'lib'), File.dirname(__FILE__))

__END__

Needed "require 'test/unit'" before "require 'spec'" due to an error below with autospec.

/home/ice/.gem/ruby/1.8/gems/rspec-1.1.11/lib/spec.rb:25:in `exit?': undefined method `run?' for Test::Unit:Module (NoMethodError)
        from /home/ice/.gem/ruby/1.8/gems/rspec-1.1.11/lib/spec/runner.rb:192:in `register_at_exit_hook'
        from spec/messa/db/clawler/page_data_spec.rb:9

ref: http://www.ruby-forum.com/topic/170889
