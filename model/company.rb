class Company < Sequel::Model
  FORM_LABEL = {
    :name => 'Company name',
    :founded => 'Year founded',
    :text => 'Company description',
    :employees => 'No. of Employees',
  }

  set_schema do
    primary_key :id

    varchar :name
    integer :founded
    varchar :employees
    string :text

    boolean :logo_show, :default => false
    varchar :logo_mime

    foreign_key :user_id
  end

  belongs_to :user
  many_to_many :jobs

  create_table unless table_exists?

  validations.clear
  validates do
    length_of :founded, :is => 4
    numericality_of :founded, :only_integer => true
    uniqueness_of :name
    format_of :employees, :with => /^\d+(\+|-\d+)$/
  end

  def self.search(*words)
    terms = words.map{|word| "%#{word}%" }
    filter :name.like(*terms)
  end

  def logo=(file)
    temp = file[:tempfile]

    ext = logo_ext || File.extname(file[:filename])
    logo_file = Ramaze::Global.public_root/"logo/#{self.id}#{ext}"

    FileUtils.mkdir_p File.dirname(logo_file)
    FileUtils.cp temp.path, logo_file

    self.logo_show = true
    self.logo_mime = Ramaze::Tool::MIME.type_for(logo_file)
  end

  # Links

  include ModelLink

  def to_logo
    "/logo/#{self.id}#{logo_ext}"
  end

  def to_search
    R(SearchController, :q => name, :only => :company)
  end

  include FormField::Model

  private

  def logo_ext
    Ramaze::Tool::MIME.ext_for(logo_mime)
  end
end
