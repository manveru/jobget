# Stdlib
require 'erb'
require 'logger'

# Bootstrap
require 'rubygems'
require 'ramaze'

Ramaze.setup do
  gem 'sequel', '=2.12.0'
  gem 'haml', '=2.0.9'
  gem 'faker'
  gem 'maruku'
  gem 'image_science'
end

# Contrib
require 'ramaze/contrib/email'
require 'ramaze/contrib/sequel/image'
require 'ramaze/contrib/sequel/create_join'
require 'ramaze/contrib/sequel/form_field'
require 'ramaze/contrib/sequel/relation'

# Vendor
Ramaze::acquire('vendor/*.rb')

# configuration
require 'env'

# app
require 'model/init'
require 'controller/init'
