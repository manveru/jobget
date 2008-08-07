class ResumeController < Controller
  def index
    must_login 'to view your Resumes'

    @resumes = user.resumes
  end

  def create
    must_login 'to create a new Resume'
    must_post 'to create a new Resume'

    resume = Resume.from_request(user, request)
    save(resume)
  end

  def edit(resume_id)
    redirect_referrer unless logged_in? and request.post?
    resume = Resume[resume_id.to_i]
    resume.public = request[:public]
    pp resume.public
    save(resume)
  end


  def read(id)
    @resume = Resume[id.to_i]
    # h Resume.all.inspect
  end

  def download(id)
    if resume = Resume[id.to_i]
      if user == resume.user or resume.companies === user.company
        # response['Content-Disposition'] = resume.link_ref + ".#{ext}"
        response['Content-Type'] = resume.mime
        respond File.open(resume.original)
        # if user.company == resume.company or user == resume.user
        #   pp resume
        # end
      end
    end
  end

  def delete(id)
    if resume = Resume[id.to_i]
      if user == resume.user
        resume.delete
      else
        flash[:bad] = "Requested Action not allowed"
      end
    else
      flash[:bad] = "Requested Resume wasn't found"
    end
  end

  private

  def save(resume)
    if resume.valid?
      if resume.user_id == user.id
        resume.save
      else
        flash[:bad] = 'Permission denied'
      end

      redirect_referrer
    else
      flash[:bad] = resume.errors.inspect
    end
  end
end
