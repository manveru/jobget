module JobGet
  class CompanyController < Controller
    def edit
      acl "in order to change company details", :recruiter
      @company = user.company

      if request.post?
        result = @company.profile_update(request)
        flash.merge!(result)
        redirect_referrer
      end
    end

    def update
      must_login 'before updating your profile'
      must_post 'in order to update your profile'

      result = user.profile_update(request)
      flash.merge! result
      redirect_referrer
    end

    def toggle_logo
      acl 'change your logo', :recruiter

      company = user.company
      company.show_logo = !company.show_logo
      company.save
      redirect r(:edit)
    end
  end
end
