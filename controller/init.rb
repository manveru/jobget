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
    root = Ramaze::Global.root/controller.view_root.first
    render_template("#{root}/_#{name}.haml", *args)
  end
end

acquire 'controller/*.rb'
