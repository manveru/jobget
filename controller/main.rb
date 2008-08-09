class MainController < Controller
  def index
    # Use .all to force use of :eager
    @featured = Job.featured(5).all
    @latest = Job.latest(5).all
  end
end
