module JobGet
  class Stats < Controller
    map '/stat'

    def index
      @stats = Stat.for_ip(request.ip)
      pager @stats
    end

    def search
      @terms, @cateogry = @search.terms, @search.category
      @title ="Search for %p in %p" % [@terms, @category]
    end
  end
end
