require 'vendor/any2text'

class CV < Sequel::Model
  set_schema do
    primary_key :id

    varchar :title
    varchar :mime
    string :text

    # File locations
    varchar :txt
    varchar :original

    time :created_at
    time :updated_at

    foreign_key :user_id
  end

  belongs_to :user
  many_to_many :jobs, :class => :Job, :join_table => 'cvs_jobs'

  create_table unless table_exists?

  hooks.clear
  before_create{ self.created_at = Time.now }
  before_save{ self.updated_at = Time.now }

  # Why does this not work out of the box?
  def add_job(job)
    CV.db[:cvs_jobs].insert(:cv_id => id, :job_id => job.id)
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

  include Ramaze::Helper::Link

  def to_download
    ext = Any2Text::MIME_ID[mime]
    R(CVController, :download, link_ref + ".#{ext}")
  end

  def to_read
    R(CVController, :read, link_ref)
  end

  def link_ref
    [id, *title.scan(/\w+/)].join('-')
  end
end
