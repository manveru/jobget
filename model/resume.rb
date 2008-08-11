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

  hooks.clear
  before_create{ self.created_at = Time.now }
  after_create{ User[user_id].add_resume(self) }
  before_save{ self.updated_at = Time.now }

  before_destroy do # a cleanup of Job/Resume associations and delete files
    applications.each do |app|
      app.destroy
    end

    FileUtils.rm_f(txt)
    FileUtils.rm_f(original)
  end

  def self.from_request(user, request)
    title, file = request[:title], request[:file]
    mime, temp = file[:type], file[:tempfile]
    mime = mime.split.first

    resume = Resume.new(:title => title, :user_id => user.id, :mime => mime)

    a2t = Any2Text.new(temp.path)
    resume.text = a2t.try_convert(mime)
    resume.save

    name = title.to_s.gsub(/\W+/u, '-').gsub(/-*$/, '')
    file = [user.id, resume.id, name].join('_')
    pp a2t

    txt, ext = a2t.save_both("resume/#{file}")
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
