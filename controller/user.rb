class UserController < Controller
  def login
    @email, @password = request[:email, :password]

    case request[:fail]
    when 'session'
      flash[:bad] =
        'Failed to login, please make sure you have cookies enabled for this site'
    end

    return unless request.post?

    if user_login :email => @email, :crypt => User.encrypt(@password)
      flash[:good] = 'Welcome back'
      redirect Rs(:after_login)
      answer Rs(:read)
    else
      flash[:bad] = 'Failed to login, please check your input'
    end
  end

  # Make sure we really did login, a browser without cookies would fail.
  def after_login
    if logged_in?
      answer Rs(:read)
    else
      redirect Rs(:login, :fail => :session)
    end
  end

  def join
    pp request.params
    @role = request[:role] || 'applicant'

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
          answer Rs(:read)
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

  def edit(user_id = nil)
    must_login 'in order to access your profile'

    if user.admin? and user_id
      @user = User[user_id.to_i]
    else
      @user = user
    end
  end

  def read(user_id = nil)
    must_login 'in order to access this profile'
    @user = user_id ? User[user_id.to_i] : user

    unless @user.visible_to?(user)
      flash[:bad] = 'You are not allowed to view this profile'
      redirect_referrer
    end
  end

  def list
    acl 'to see this page', :admin
    paginate(@users = User, 50)
  end

  def update
    must_login 'before updating your profile'
    must_post 'in order to update your profile'

    result = user.profile_update(request)
    flash.merge! result
    redirect_referrer
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

      redirect Rs(:read)
    else
      pp user.errors
    end
  end

  template :update_password, :edit

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

    redirect Rs(:read)
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
