class CompanyController < Controller
  def edit
    acl "in order to change company details", :recruiter
    @company = user.company

    if request.post?
      @company.set_values request.subset(*Company::FORM_LABEL.keys)

      if file = request[:logo]
        @company.logo = file
      end

      @company.save
    end
  end
end
