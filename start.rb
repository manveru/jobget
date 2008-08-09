# Stdlib
require 'erb'
require 'logger'

# Gems
require 'rubygems'
require 'ramaze'
require 'sequel'
require 'faker'
require 'maruku'
require 'configuration'

# Hacks and custom libs
require 'vendor/any2text'
require 'vendor/form_field'
require 'vendor/model_link'
require 'vendor/create_join'
require 'vendor/paginator'

# Contrib
require 'ramaze/contrib/email'

# App
require 'env'
require 'controller/init'
require 'model/init'

handle_error = Ramaze::Dispatcher::Error::HANDLE_ERROR
handle_error.clear
handle_error.merge!(
  Object                  => [500, '/error/internal_server_error'],
  Ramaze::Error::NoAction => [404, '/error/not_found']
)

# Let's go!
Ramaze.start :adapter => :mongrel
