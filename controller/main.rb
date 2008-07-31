class MainController < Controller
  def index
    # Use .all to force use of :eager
    @featured = Job.featured(100).all
    @latest = Job.latest(100).all
  end

  def search
    @results = []

    if @q = request[:q]
      case request[:only]
      when 'job'
        search_jobs
      when 'company'
        search_companies
      else
        search_jobs
        search_companies
      end
    end

    @results.uniq!
  end

  private

  def search_jobs
    Job.search(@q).each{|job| @results << job }
  end

  def search_companies
    Company.search(@q).each do |company|
      company.jobs.each do |job|
        @results << job if job.available?
      end
    end
  end
end
