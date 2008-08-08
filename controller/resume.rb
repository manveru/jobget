class ResumeController < Controller
  def index
    acl 'to view your Resumes', :applicant

    @resumes = user.resumes
  end

  def create
    acl 'to create a new Resume', :applicant
    must_post 'to create a new Resume'

    resume = Resume.from_request(user, request)
    save(resume)
  end

  def edit(resume_id)
    acl "to edit this Resume", :applicant
    must_post "to edit a Resume"

    resume = Resume[resume_id.to_i]
    resume.public = request[:public]
    pp resume.public
    save(resume)
  end


  def read(id)
    acl "to view a Resume", :applicant

    @resume = Resume[id.to_i]
    pp @resume
    # h Resume.all.inspect
  end

  def download(id)
    must_login "to download this Resume", :applicant, :recruiter

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
    acl "to delete this Resume", :applicant

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
