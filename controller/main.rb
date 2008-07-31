class MainController < Controller
  def index
    # Use .all to force use of :eager
    @featured = Job.featured(100).all
    @latest = Job.latest(100).all
  end
end
