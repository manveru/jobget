require 'ramaze'
require 'sequel'
require 'faker'
require 'maruku'
require 'erb'

require 'env'

require 'vendor/any2text'
require 'vendor/form_field'
require 'vendor/model_link'
require 'vendor/create_join'
require 'vendor/paginator'

require 'controller/init'
require 'model/init'

Ramaze.start :adapter => :mongrel
