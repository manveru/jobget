class CVController < Controller
  map '/cv'

  def index
    call(R(UserController, :login)) unless logged_in?
    @cvs = user.cvs
  end

  def create
    redirect_referrer unless logged_in? and request.post?

    title, file = request[:title, :file]
    mime, temp = file[:type], file[:tempfile]

    cv = CV.new(:title => title, :user_id => user.id, :mime => mime)

    a2t = Any2Text.new(temp.path)
    cv.text = a2t.try_convert
    txt, ext = a2t.save_both("cv/#{user.id}_#{cv.text.hash}")
    cv.txt = txt
    cv.original = ext

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
      cv.save
      redirect_referrer
    else
      flash[:bad] = cv.errors.inspect
    end
  end
end
