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

  if ARGV.include?('--mode')
    Ramaze::Global.merge!(ARGV)
    Configuration.for(:jobget){ mode Ramaze::Global.mode.to_sym }
  end

  require 'controller/init'
  require 'model/init'

  # Conf
  global.adapter = :mongrel
  global.sourcereload = 1
end
