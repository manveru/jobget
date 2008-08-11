conf = Configuration.for(:jobget)

case conf.mode.to_sym
when :live
  puts "Starting live mode, connecting to db"
  DB = Sequel.connect conf.db # , :logger => Logger.new($stdout)
  acquire 'model/*.rb'
when :spec
  puts "Starting spec mode"
  DB = Sequel.sqlite # :logger => Logger.new($stdout)
  acquire 'model/*.rb'
  require 'db/init_relations'
when :dev
  puts "Starting dev mode"
  DB = Sequel.sqlite # :logger => Logger.new($stdout)
  acquire 'model/*.rb'
  require 'db/init_relations'
  require 'db/fill'
else
  raise "Invalid mode"
end
