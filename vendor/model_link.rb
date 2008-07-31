module ModelLink
  include Ramaze::Helper::Link

  def to(action, *args)
    if respond_to?(meth = "to_#{action}")
      send(meth, *args)
    else
      klass = constant("#{self.class.name}Controller")
      R(klass, action, link_ref, *args)
    end
  end

  def href(text, *args)
    Ramaze::Gestalt.new.a(:href => to(*args)){ text }
  end

  def link_ref
    [id, *title.scan(/\w+/)].join('-')
  end
end
