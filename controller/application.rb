class ApplicationController < Controller
  def index
    call R(UserController, :login) unless logged_in?

    @sent = user.cvs_sent
    @got = user.cvs_got
  end
end
