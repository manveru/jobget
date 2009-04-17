module JobGet
  class CSSController < Ramaze::Controller
    map '/css'
    provide :css, :engine => :Sass
  end
end
