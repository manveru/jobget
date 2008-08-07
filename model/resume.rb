class Resume < Sequel::Model
  FORM_LABEL = {
    :public => 'Resume can be searched by other users',
  }

  set_schema do
    primary_key :id

    varchar :title
    string :text

    boolean :public

    # Storage
    varchar :mime

    # File locations
    varchar :txt
    varchar :original

    time :created_at
    time :updated_at

    foreign_key :user_id
  end

  belongs_to :user
  many_to_many :jobs

  create_table unless table_exists?

  hooks.clear
  before_create{ self.created_at = Time.now }
  before_save{ self.updated_at = Time.now }
  before_delete do
    # DB['cvs_jobs'].find(:cv_id => id).delete
  end

  def self.from_request(user, request)
    title, file = request[:title], request[:file]
    mime, temp = file[:type], file[:tempfile]

    resume = Resume.new(:title => title, :user_id => user.id, :mime => mime)

    a2t = Any2Text.new(temp.path)
    resume.text = a2t.try_convert
    txt, ext = a2t.save_both("resume/#{user.id}_#{resume.text.hash}")
    resume.txt = txt
    resume.original = ext
    resume
  end

  def self.searchable
    filter(:public => true)
  end

  def self.search(*words)
    terms = words.map{|word| "%#{word}%" }

    searchable.filter do |resume|
      resume.text.like(*terms)
    end
  end

  # View

  def preview
    text.lstrip[0..50] + '...'
  end

  def updated_formatted
    updated_at.strftime('%Y-%m-%d')
  end

  def created_formatted
    created_at.strftime('%Y-%m-%d')
  end

  # Links

  include ModelLink

  def to_download
    ext = Any2Text::MIME_ID[mime]
    R(ResumeController, :download, link_ref + ".#{ext}")
  end

  include FormField::Model
end
