class CVController < Controller
  map '/cv'

  def index
    call(R(UserController, :login)) unless logged_in?
    @cvs = user.cvs
  end

  def create
    redirect_referrer unless logged_in? and request.post?

    cv = CV.from_request(user, request)
    save(cv)
  end

  def edit(cv_id)
    redirect_referrer unless logged_in? and request.post?
    cv = CV[cv_id.to_i]
    cv.public = request[:public]
    pp cv.public
    save(cv)
  end


  def read(id)
    @cv = CV[id.to_i]
    # h CV.all.inspect
  end

  def download(id)
    if cv = CV[id.to_i]
      if user == cv.user or cv.companies === user.company
        # response['Content-Disposition'] = cv.link_ref + ".#{ext}"
        response['Content-Type'] = cv.mime
        respond File.open(cv.original)
        # if user.company == cv.company or user == cv.user
        #   pp cv
        # end
      end
    end
  end

  private

  def save(cv)
    if cv.valid?
      if cv.user_id == user.id
        cv.save
      else
        flash[:bad] = 'Permission denied'
      end

      redirect_referrer
    else
      flash[:bad] = cv.errors.inspect
    end
  end
end
