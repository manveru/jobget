class UserController < Controller
  def login
    @email, @password = request[:email, :password]
    return unless request.post?

    pp session

    if user_login :email => @email, :crypt => User.encrypt(@password)
      flash[:good] = 'Welcome back'
      answer Rs(:profile)
    else
      flash[:bad] = 'Failed to login, please check your input'
    end
  end

  def join
    pp request.params

    @user = User.new
    @user.set_values(request.subset(*User::FORM))

    if request.post?
      @user.password, @user.password_confirmation =
        request[:password, :password_confirmation]

      @user.crypt = User.encrypt(@user.password)

      if @user.valid?
        if request[:tos]
          @user.save
          user_login(:email => @user.email, :crypt => @user.crypt)
          answer Rs(:profile)
        else
          @user.errors.add(:tos, 'Terms of Service are not confirmed')
          # redirect_referrer
        end
      end
    end
  end

  def logout
    user_logout
    session.clear
    flash[:good] = 'Logged out'
    answer R(:/)
  end

  def profile
    must_login 'in order to access your profile'

    @cvs = user.cvs
    @jobs = @cvs.map{|cv| cv.jobs }.flatten.uniq
  end

  def update
    must_login 'before updating your profile'

    user.profile_update(request)

    if user.valid?
      user.save
      flash[:good] = "Profile updated"
      redirect_referrer
    else
      flash[:bad] = user.errors.inspect
    end
  end

  def update_password
    must_login 'before changing your password'

    user.password, user.password_confirmation =
      request[:password, :password_confirmation]

    user.crypt = User.encrypt(user.password)

    if user.valid?
      user.save

      session.delete :USER
      user_login(:email => user.email, :crypt => user.crypt)
      flash[:good] = 'Password changed'

      redirect Rs(:profile)
    else
      pp user.errors
    end
  end

  template :update_password, :profile

  def forgot_login
    email, hash = request[:email, :hash]
    redirect_referrer if hash.strip.empty?

    if user = User[:email => email, :reset_hash => hash]
      user_login(:email => email, :crypt => user.crypt)

      flash[:good] = "Logged in, please reset your password now"

      user.reset_hash = ''
      user.save
    else
      flash[:bad] = "Unable to login this way"
    end

    redirect Rs(:profile)
  end

  def forgot
    @email = request[:email]

    return unless request.post?

    if user = User[:email => @email]
      user.reset_password

      flash[:good] = "We sent you an email that allows you to login. Please change your password as soon as possible."

      redirect R(MainController, :/)
    else
      flash[:bad] = "No user for this address found"
      redirect_referrer
    end
  end
end
