module JobGet
  class CSS < Ramaze::Controller
    map '/css'
    provide :css, :engine => :Sass
  end
end
