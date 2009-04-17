module JobGet
  class Controller < Ramaze::Controller
    helper :xhtml, :user, :stack, :formatting, :paginate
    engine :Haml
    layout 'default'

    trait :user_model => User

    private

    def conf
      JobGet.options
    end

    def must_login(message, target = nil)
      return if logged_in?
      flash[:bad] = "You have to login #{message}"
      call target || UserController.r(:login)
    end

    def must_post(message, target = nil)
      return if request.post?
      flash[:bad] = "Request should be POST #{message}"
      target ? redirect(target) : redirect_referrer
    end

    def acl(message, *list)
      list.map!{|l| l.to_s }
      list << 'admin'

      must_login(message)

      if list.include?(user.role)
        return true
      else
        flash[:bad] = "Access denied"
        answer request.referrer
      end
    end

    def pager(dataset, limit = 5)
      @pager = paginate(dataset, :limit => limit)
    end

    def pager_navigation
      return nil unless @pager
      @pager.navigation if @pager.needed?
    end
  end
end

Ramaze::acquire 'controller/*.rb'
