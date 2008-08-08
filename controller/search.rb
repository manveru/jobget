class SearchController < Controller
  def index
    @by = %w[any job skill company]
    @q, @only = request[:q, :only]
    @only ||= 'any'
    @results = []

    if @q
      case @only
      when *@by
        send("search_#@only")
      else
        search_any
      end
    end

    Stat.log_search(:terms => @q, :category => @only)

    @results.uniq!
    nav @results
  end

  def resume
    if resume = request[:resume]
      @results = Resume.search(resume).all
    else
      @results = []
    end
  end

  private

  def search_any
    search_skill
    search_job
    search_company
  end

  def search_skill
    @results += Job.available.filter{|job|
      job.skills.like("%#@q%")
    }.all
  end

  def search_job
    Job.search(@q).each{|job| @results << job }
  end

  def search_company
    Company.search(@q).each do |company|
      company.jobs.each do |job|
        @results << job if job.available?
      end
    end
  end
end
