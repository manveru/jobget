module JobGet
  class MainController < Controller
    def index
      @featured = Job.featured
      @f_pager = paginate(@featured, :limit => 3, :var => :featured)

      @latest = Job.latest
      @l_pager = paginate(@latest, :limit => 3, :var => :latest)
    end
  end
end
