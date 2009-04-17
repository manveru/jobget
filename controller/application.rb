module JobGet
  class ApplicationController < Controller
    def index
      must_login 'to view applications'

      @applications = Application.for_user(user)
    end
  end
end
