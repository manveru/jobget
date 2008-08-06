require 'ramaze'
require 'sequel'
require 'faker'
require 'maruku'
require 'erb'

require 'env'

require 'controller/init'
require 'model/init'

Ramaze.start :adapter => :mongrel
