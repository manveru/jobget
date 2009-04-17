module JobGet
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

    def self.for_ip(ip)
      filter(:ip => ip).order(:created_at.desc)
    end
  end

  class SearchStat < Sequel::Model
    set_schema do
      primary_key :id

      varchar :terms
      varchar :category

      foreign_key :stat_id
    end

    create_table unless table_exists?
  end

  class JobViewStat < Sequel::Model
    set_schema do
      primary_key :id

      foreign_key :stat_id
      foreign_key :job_id
    end

    create_table unless table_exists?
  end
end
