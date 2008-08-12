class Controller < Ramaze::Controller
  map nil
  helper :xhtml, :user, :stack, :formatting, :paginate
  engine :Haml
  layout '/layout'

  private

  def conf
    Configuration.for(:jobget)
  end

  def part(name, controller = nil, *args)
    controller ||= Ramaze::Action.stack[0].controller

    if res = controller.resolve_template("_#{name}")
      template = Ramaze::Global.root/res
      render_template(template, *args)
    else
      ''
    end
  end

  def must_login(message, target = nil)
    return if logged_in?
    flash[:bad] = "You have to login #{message}"
    call target || R(UserController, :login)
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

  def paginate(dataset, limit = 5)
    page = (request[:pager] || 1).to_i
    @pager = Paginator.new(dataset, page, limit)
  end

  def pager_navigation
    return nil unless @pager
    @pager.navigation if @pager.needed?
  end
end

acquire 'controller/*.rb'
