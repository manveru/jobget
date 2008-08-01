class Controller < Ramaze::Controller
  map nil

  def self.inherited(klass)
    super
    klass.helper :xhtml, :user, :stack, :formatting
    klass.engine :Haml
    klass.layout '/layout'
  end

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
end

acquire 'controller/*.rb'
