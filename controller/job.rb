class JobController < Controller
  map '/job'

  def read(job_id)
    @job = job_for(job_id)
    Stat.log_view(:job_id => @job.id)
  end

  def browse
    @jobs = Job.available
    paginate @jobs
  end

  def apply(job_id)
    acl 'before applying for this job', :applicant

    @job = job_for job_id
    resumes_for user
  end

  def submit_resume(job_id)
    acl 'before submitting a Resume', :applicant

    job = job_for(job_id)

    if resume = Resume[:id => request[:resume], :user_id => user.id]
      if resume.jobs.include?(job)
        flash[:bad] = 'You already submitted a Resume for this job'
      else
        flash[:good] = 'Submitted Resume'
        resume.add_job(job)
      end
    end

    redirect Rs(:read, job.id)
  end

  def post
    acl 'before posting a job', :recruiter

    @job = Job.from_request(request)
    @job.company = company = user.company

    return unless request.post?
    # Workaround to force boolean...
    @job.open = !!request[:open]
    @job.public = !!request[:public]

    if @job.valid?
      @job.save
      company.add_job(@job)
      flash[:good] = 'Job created'
      redirect @job.to(:read)
    else
      flash[:bad] = @job.errors.inspect
      redirect_referrer
    end
  end

  def state(job_id)
    acl 'before changing state of job', :recruiter

    if job = Job[:company_id => user.company.id, :id => job_id.to_i]
      if publicity = request[:public]
        job.public = publicity == 'true'
        done = job.public ? 'available for the public' : 'unavailable for the public'
      elsif opened = request[:open]
        job.open = opened == 'true'
        done = job.open ? 'opened for applications' : 'closed for applications'
      else
        flash[:bad] = "The requested action is not allowed"
        redirect_referrer
      end

      job.save

      flash[:good] = "'#{h job.title}' is #{done}"
      redirect job.to(:read)
    else
      flash[:bad] = "The requested action is not allowed"
      redirect_referrer
    end
  end

  def manage
    acl 'before managing your jobs', :recruiter

    @company = user.company
    @jobs = @company.jobs.reverse
  end

  def edit(job_id)
    acl 'before editing this job', :recruiter

    @job = job_for(job_id)

    if @job.company == user.company
      return unless request.post?
      @job.set_values(request.subset(*Job::FORM))
      # Workaround to force boolean...
      @job.open = !!request[:open]
      @job.public = !!request[:public]

      try_save(@job, 'Job updated')
    else
      flash[:bad] = "The requested action is not allowed"
      redirect_referrer
    end
  end
  template :edit, :post

  def delete(job_id)
    acl 'before deleting this job', :recruiter

    if job = Job[:company_id => user.company.id, :id => job_id.to_i]
      job.delete
      flash[:good] = "Job deleted"
      redirect_referrer
    else
      flash[:bad] = "The requested action is not allowed"
      redirect_referrer
    end
  end

  private

  def job_for(job_id)
    id = job_id.to_i

    if logged_in? and job = Job[:company_id => user.company.id, :id => id]
      return job
    end

    return job if job = Job.available[:id => id]

    flash[:bad] = "The requested job is not available"
    redirect_referrer
  end

  def resumes_for(user)
    @resumes = user.resumes

    if @resumes.empty?
      flash[:bad] = 'Please create a Resume before you apply'
      call R(UserController, :profile)
    end
  end

  def try_save(job, message, to = request.referrer)
    if job.valid?
      job.save
      flash[:good] = message
      redirect to
    else
      flash[:bad] = h(job.errors.inspect)
      redirect to
    end
  end
end
