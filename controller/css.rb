class CSSController < Ramaze::Controller
  engine :Sass
end

Ramaze::Rewrite[/^(.*)\.css$/] = '%s'
