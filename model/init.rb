conf = Configuration.for(:jobget)

case conf.mode
when :live
  DB = Sequel.connect conf.db # , :logger => Logger.new($stdout)
  acquire 'model/*.rb'
else
  DB = Sequel.sqlite # , :logger => Logger.new($stdout)
  acquire 'model/*.rb'
  require 'db/init'
end
