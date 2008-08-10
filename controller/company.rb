class CompanyController < Controller
  def edit
    acl "in order to change company details", :recruiter
    @company = user.company

    if request.post?
      @company.set_values request.subset(*Company::FORM_LABEL.keys)

      if file = request[:logo]
        begin
          @company.update_logo file
        rescue TypeError => ex
          Ramaze::Log.error(ex)
          flash[:bad] = "The submitted image cannot be processed."
          redirect_referrer
        end
      end

      @company.save
    end
  end

  def toggle_logo
    acl 'change your logo', :recruiter

    company = user.company
    company.show_logo = !company.show_logo
    company.save
    redirect Rs(:edit)
  end
end
