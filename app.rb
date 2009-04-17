# Stdlib
require 'erb'
require 'logger'

# Bootstrap
require 'rubygems'
require 'ramaze'

Ramaze.setup do
  gem 'sequel'
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

# app
require 'model/init'
require 'controller/init'

# configuration
require 'env'
