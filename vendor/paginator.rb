require 'cgi'
require 'ramaze/gestalt'

class Paginator
  class ArrayPager
    def initialize(array, page, limit)
      @array, @page, @limit = array, page, limit
      @page = page_count if @page > page_count
    end

    def size
      @array.size
    end

    def empty?
      @array.empty?
    end

    def page_count
      pages, rest = @array.size.divmod(@limit)
      rest == 0 ? pages : pages + 1
    end

    def current_page
      @page
    end

    def next_page
      page_count == @page ? nil : @page + 1
    end

    def prev_page
      @page <= 1 ? nil : @page - 1
    end

    def first_page?
      @page <= 1
    end

    def last_page?
      page_count == @page
    end

    def each(&block)
      from = (@page - 1).abs
      to = ((@page + @limit) - 1).abs
      p :page => @page, :from => from
      p :limit => @limit, :to => to
      a = @array[from...to] || []
      a.each(&block)
    end

    include Enumerable
  end

  def initialize(data, page, limit = 10, nav_limit = nil)
    @data, @page, @limit = data, page, limit
    @pager = pager_for(data)
    @nav_limit = nav_limit || @pager.page_count
  end

  def pager_for(obj)
    case obj
    when Array
      ArrayPager.new(obj, @page, @limit)
    else
      obj.paginate(@page, @limit)
    end
  end

  def navigation
    out = [ g.div(:class => :pager) ]

    if first_page?
      out << g.span(:class => 'first grey'){ '<<' }
      out << g.span(:class => 'previous grey'){ '<' }
    else
      out << link(1, '<<', :class => :first)
      out << link(prev_page, '<', :class => :previous)
    end

    (1...current_page).each do |n|
      out << link(n)
    end

    out << link(current_page, current_page, :class => :current)

    if last_page?
      out << g.span(:class => 'next grey'){ '>' }
      out << g.span(:class => 'last grey'){ '>>' }
    else
      (next_page..page_count).each do |n|
        out << link(n)
      end

      out << link(next_page, '>', :class => :next)
      out << link(page_count, '>>', :class => :last)
    end

    out << '</div>'
    out.map{|e| e.to_s}.join("\n")
  end

  include Ramaze::Helper::Link

  def link(n, text = n, hash = {})
    text = CGI.escapeHTML(text.to_s)

    params = Ramaze::Request.current.params.merge('pager' => n)
    hash[:href] = Rs(Ramaze::Action.current.name, params)

    g.a(hash){ text }
  end

  def g
    Ramaze::Gestalt.new
  end

  def needed?
    @pager.page_count > 1
  end

  def method_missing(meth, *args, &block)
    @pager.send(meth, *args, &block)
  end
end

__END__
# paginated = dataset.paginate(1, 10) # first page, 10 rows per page
# paginated.page_count #=> number of pages in dataset
# paginated.current_page #=> 1
# paginated.next_page #=> next page number or nil
# paginated.prev_page #=> previous page number or nil
# paginated.first_page? #=> true if page number = 1
# paginated.last_page? #=> true if page number = page_count

require 'sequel'
require 'faker'
db = Sequel.sqlite

class User < Sequel::Model
  set_schema do
    primary_key :id
    varchar :name
  end

  create_table
end

100.times do
  User.create :name => Faker::Name::name
end

# Takes Sequel dataset or model
pager = Paginator.new(User, 2, 10)
puts pager.navigation

# Also takes Array
pager = Paginator.new((1..100).to_a, 2, 10)
puts pager.navigation
