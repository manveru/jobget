class Job < Sequel::Model
  FORM = [
    :title, :text,
    :internal, :contract, :location,
    :salary_interval, :salary_low, :salary_high,
    :public, :open
  ]

  FORM_LABEL = {
    :title => 'Job Title',
    :internal => 'Internal ID',
    :location => 'Job Location',
    :contract => 'Contract Type',
    :salary_interval => 'Salary Interval',
    :salary_low => 'Salary Low',
    :salary_high => 'Salary High',
    :public => 'Publicly visible',
    :open => 'Open for applications',
    :text => 'Job Description',
  }

  CONTRACTS = %w[ Premament Freelance ]
  SALARIES = %w[Hourly Daily WeeklyMonthly Yearly]

  set_schema do
    primary_key :id

    varchar :title
    string :text

    varchar :internal
    varchar :contract
    varchar :location

    varchar :salary_currency
    varchar :salary_interval
    integer :salary_low
    integer :salary_high

    time :created_at
    time :updated_at
    time :expires_at

    date :starts_at

    boolean :featured, :default => true
    boolean :public, :default => true
    boolean :open, :default => true

    foreign_key :company_id
  end

  many_to_many :cvs, :class => :CV, :join_table => 'cvs_jobs'
  # User.has_many :cvs, :class=>:CV, :key=>:user_id
  belongs_to :company

  create_table unless table_exists?

  validations.clear
  validates do
    numericality_of :salary_low, :only_integer => true, :allow_nil => true
    numericality_of :salary_high, :only_integer => true, :allow_nil => true

    format_of :title, :with => /\A[^\n\r]+\z/, :message => 'May not contain newlines'
    presence_of :company_id
  end

  hooks.clear
  before_create{ self.created_at = Time.now }
  before_save{ self.updated_at = Time.now }


  def self.latest(n = 10)
    available.limit(n).filter(:featured => false)
  end

  def self.featured(n = 10)
    available.limit(n).filter(:featured => true)
  end

  def self.available(n = 10)
    filter(:open => true, :public => true).
      eager(:company).
      order(:updated_at.desc)
  end

  def available?
    open and public
  end

  # TODO: Optimize
  def self.search(*words)
    terms = words.map{|word| "%#{word}%" }

    available.filter{|job|
      job.title.like(*terms) | job.text.like(*terms)
    }.all
  end

  def related(n = 5)
    words = title.scan(/\w+/)
    (Job.search(*words) - [self]).first(n)
  end

  # View

  include Ramaze::Helper::Formatting

  def salary
    s_low = number_format(salary_low)
    s_high = number_format(salary_high)
    "#{s_low} ~ #{s_high} / #{salary_interval}"
  end

  def preview
    text.to_s.lines.first(2).join("<br />\n")[0..255] + '...'
  end

  def updated_formatted
    updated_at.strftime('%Y-%m-%d')
  end

  def created_formatted
    created_at.strftime('%Y-%m-%d')
  end

  # Links

  include Ramaze::Helper::Link

  def to_apply
    R(JobController, :apply, link_ref)
  end

  def to_read
    R(JobController, :read, link_ref)
  end

  def to_state(args = {})
    R(JobController, :state, link_ref, args)
  end

  def to_edit
    R(JobController, :edit, link_ref)
  end

  def to_delete
    R(JobController, :delete, link_ref)
  end

  def link_ref
    [id, *title.scan(/\w+/)].join('-')
  end

  # Forms

  def self.from_request(request)
    instance = new
    instance.set_values(request.subset(*FORM)) if request.post?
    instance
  end

  include FormField::Model
end
