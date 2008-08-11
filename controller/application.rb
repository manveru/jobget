class ApplicationController < Controller
  def index
    must_login 'to view applications'

    @applications = Application.
      filter(:user_id => user.id).
      or(:company_id => user.company.id).
      eager(:user, :job, :company, :resume)
  end
end
