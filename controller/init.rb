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
    view_root = Ramaze::Global.root/controller.view_root
    root = view_root ? view_root.first : Ramaze::Global.view_root/controller.mapping
    render_template("#{root}/_#{name}.haml", *args)
  end
end

acquire 'controller/*.rb'
