class ApplicationController < Controller
  def index
    must_login 'to view applications'

    @sent = user.resumes_sent
    @got = user.resumes_got
  end
end
