module JobGet
  class ResumeController < Controller
    def index
      acl 'to view your Resumes', :applicant

      @resumes = user.resumes
      @resumes = Resume.filter(:user_id => user.id)
    end

    def create
      acl 'to create a new Resume', :applicant
      must_post 'to create a new Resume'

      resume = Resume.from_request(user, request)
      save(resume)
    rescue Any2Text::CannotConvert => ex
      Ramaze::Log.error(ex)
      flash[:bad] = "The submitted resume cannot be processed."
      redirect_referrer
    end

    def toggle_public(resume_id)
      acl "to change visibility of this Resume", :applicant

      if resume = Resume[resume_id.to_i]
        resume.public = !resume.public
        save(resume)
      else
        flash[:bad] = "Requested Resume wasn't found"
      end

      redirect_referrer
    end

    def read(id)
      acl "to view a Resume", :applicant

      return if @resume = Resume[id.to_i]

      flash[:bad] = "Requested Resume wasn't found"
      redirect_referrer
    end

    def download(id)
      acl "to download this Resume", :applicant, :recruiter

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
          resume.destroy # runs hooks
        else
          flash[:bad] = "Requested Action not allowed"
        end
      else
        flash[:bad] = "Requested Resume wasn't found"
      end

      redirect Rs(:/)
    end

    private

    def save(resume)
      if resume.valid?
        if resume.user_id == user.id
          resume.save
        else
          flash[:bad] = 'Permission denied'
        end

        answer request.referrer
      else
        flash[:bad] = resume.errors.inspect
      end
    end
  end
end
