module JobGet
  class Users < Controller
    map '/user'

    def index
      redirect Main.r(:/)
    end

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
        redirect r(:after_login)
        answer r(:read)
      else
        flash[:bad] = 'Failed to login, please check your input'
      end
    end

    # Make sure we really did login, a browser without cookies would fail.
    def after_login
      if logged_in?
        answer r(:read)
      else
        redirect r(:login, :fail => :session)
      end
    end

    def join
      request[:role] ||= 'applicant'
      @user = User.prepare(request)

      return unless request.post?
      return unless @user.joins

      user_login(:email => @user.email, :crypt => @user.crypt)
      flash[:good] = "Welcome to #{conf.title}, you can start by filling your profile."
      answer r(:read)
    end

    def logout
      user_logout
      session.clear
      flash[:good] = 'Logged out'
      answer r(:/)
    end

    def edit(user_id = nil)
      must_login 'in order to access your profile'

      @user = (user.admin? and user_id) ? User[user_id.to_i] : user

      return unless request.post?

      return unless message = @user.profile_update(request)
      flash.merge!(message)
      answer r(:read)
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
      pager(@users = User, 50)
    end

    def update(user_id = nil)
      bar
      return
      must_login 'before updating your profile'
      must_post 'in order to update your profile'

      @user = (user.admin? and user_id) ? User[user_id.to_i] : user

      result = @user.profile_update(request)
      flash.merge! result
      redirect_referrer
    end

    def update_password(user_id = nil)
      must_login 'before changing your password'
      must_post 'in order to change your password'

      @user = (user.admin? and user_id) ? User[user_id.to_i] : user

      if @user.password_update(request)
        @user.save
        flash[:good] = 'Password changed'

        if user.id == @user.id # login again with new password
          session.delete :USER
          user_login(:email => @user.email, :crypt => @user.crypt)
        end

        redirect @user.to(:read)
      else
        pp @user.errors
      end
    end

    alias_view :update_password, :edit

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

      redirect r(:read)
    end

    def forgot
      @email = request[:email]

      return unless request.post?

      if user = User[:email => @email]
        user.reset_password

        flash[:good] = "We sent you an email that allows you to login. Please change your password as soon as possible."

        redirect R(Main, :/)
      else
        flash[:bad] = "No user for this address found"
        redirect_referrer
      end
    end
  end
end
