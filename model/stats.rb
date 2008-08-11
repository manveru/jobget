class Stat < Sequel::Model
  set_schema do
    primary_key :id

    time :created_at
    varchar :ip
    varchar :referrer

    foreign_key :search_stat_id
    foreign_key :job_view_stat_id
  end

  before_create do
    self.created_at = Time.now
  end

  belongs_to :job_view_stat
  belongs_to :search_stat

  create_table unless table_exists?

  def self.log_search(hash)
    request = Ramaze::Request.current
    ip, referrer = request.ip, request.referrer

    search = SearchStat.create(hash)

    create(:ip => ip, :referrer => referrer, :search_stat_id => search.id)
  end

  def self.log_view(hash)
    request = Ramaze::Request.current
    ip, referrer = request.ip, request.referrer

    view = JobViewStat.create(hash)

    create(:ip => ip, :referrer => referrer, :job_view_stat_id => view.id)
  end
end

class SearchStat < Sequel::Model
  set_schema do
    primary_key :id

    varchar :terms
    varchar :category

    foreign_key :stat_id
  end

  belongs_to :stat

  create_table unless table_exists?
end

class JobViewStat < Sequel::Model
  set_schema do
    primary_key :id

    foreign_key :stat_id
    foreign_key :job_id
  end

  belongs_to :stat
  belongs_to :job

  create_table unless table_exists?
end

__END__
require 'sequel'
require 'logger'
require 'vendor/create_join'

DB = Sequel.sqlite(:logger => Logger.new($stdout))

class Stat < Sequel::Model
  set_schema do
    primary_key :id
    time :created_at
    varchar :ip
    varchar :referrer

    foreign_key :search_stat_id
    foreign_key :job_view_stat_id
  end

  before_create do
    self.created_at = Time.now
  end

  belongs_to :job_view_stat
  belongs_to :search_stat

  create_table
end

class SearchStat < Sequel::Model
  set_schema do
    primary_key :id
    varchar :terms
    varchar :category

    foreign_key :stat_id
  end

  belongs_to :stat

  create_table
end

class JobViewStat < Sequel::Model
  set_schema do
    primary_key :id

    foreign_key :stat_id
    foreign_key :job_id
  end

  belongs_to :stat
  belongs_to :job

  create_table
end

class Job < Sequel::Model
  set_schema do
    primary_key :id

    varchar :name
  end

  has_many :job_view_stats

  create_table
end

ip = '127.0.0.1'

stat = Stat.create :ip => ip, :referrer => 'google.com'
sstat = SearchStat.create :terms => 'some search', :category => 'job'
stat.set_values(:search_stat_id => sstat.id)
stat.save

stat = Stat.create :ip => ip, :referrer => 'yahoo.com'
job = Job.create :name => 'some job'
jstat = JobViewStat.create :job_id => job.id
stat.set_values(:job_view_stat_id => jstat.id)
stat.save

Stat.filter(:ip => ip).each do |stat|
  if jvs = stat.job_view_stat
    p jvs.job
  elsif ss = stat.search_stat
    p ss
  end
end
