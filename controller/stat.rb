class StatController < Controller
  def index
    @stats = Stat.filter(:ip => request.ip).order(:created_at.desc)
    nav @stats
  end
end
