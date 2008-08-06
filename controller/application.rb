class ApplicationController < Controller
  def index
    must_login 'to view applications'

    @sent = user.cvs_sent
    @got = user.cvs_got
  end
end
