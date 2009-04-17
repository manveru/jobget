module JobGet
  class Searches < Controller
    map '/search'

    def index
      @q, @only = request[:q, :only]
      @categories = %w[any job skill company]
      @only ||= 'any'

      @results = Job.search(@only, *@q.scan(/\S+/))

      Stat.log_search(:terms => @q, :category => @only)

      pager @results
    end

    def resume
      acl "to search for resumes", :recruiter

      if resume = request[:resume]
        @results = Resume.search(resume)
      else
        @results = []
      end

      pager @results
    end

    private

    def search_any
      @results = Job.available
    end

    def search_skill
      @results = Job.search_skill(@q)

      @results += Job.available.filter{|job|
        job.skills.like("%#@q%")
      }
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
end
