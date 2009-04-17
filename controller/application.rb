module JobGet
  class Applications < Controller
    map '/application'

    def index
      must_login 'to view applications'

      @applications = Application.for_user(user)
    end
  end
end
