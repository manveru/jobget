require File.expand_path('app', File.dirname(__FILE__))

Ramaze.start(:adapter => :mongrel, :port => 7000, :file => __FILE__)
