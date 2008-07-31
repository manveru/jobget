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
    call Rs(:login) unless logged_in?
    @cvs = user.cvs
    @jobs = @cvs.map{|cv| cv.jobs }.flatten.uniq
  end

  def update
    call Rs(:login) unless logged_in?
    user.profile_update(request)
    if user.valid?
      user.save
      flash[:good] = "Profile updated"
      redirect_referrer
    else
      flash[:bad] = user.errors.inspect
    end
  end
end
