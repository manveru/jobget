conf = Configuration.for(:jobget)

case Ramaze::Global.mode
when :live
  DB = Sequel.connect conf.db # , :logger => Logger.new($stdout)
  acquire 'model/*.rb'
when :spec
  DB = Sequel.sqlite # :logger => Logger.new($stdout)
  acquire 'model/*.rb'
  require 'db/init'
else
  DB = Sequel.sqlite # :logger => Logger.new($stdout)
  acquire 'model/*.rb'
  require 'db/init'
  require 'db/fill'
end
