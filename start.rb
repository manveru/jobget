# Stdlib
require 'erb'
require 'logger'

# Bootstrap
require 'rubygems'
require 'ramaze'

# Contrib
require 'ramaze/contrib/email'
require 'ramaze/setup'

Ramaze.setup do
  gems 'sequel', 'faker', 'maruku', 'image_science', 'configuration'

  # My hacks and libs done for this app and all generations of human mankind
  acquire 'vendor/*.rb'

  # App
  require 'env'
  require 'controller/init'
  require 'model/init'

  # Conf
  global.mode = :dev
  global.adapter = :mongrel
  global.sourcereload = 1
end
