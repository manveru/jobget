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
    template = Ramaze::Global.root / controller.resolve_template("_#{name}")
    render_template(template, *args)
  end
end

acquire 'controller/*.rb'
