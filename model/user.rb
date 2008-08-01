class User < Sequel::Model
  # self.raise_on_save_failure = false

  FORM = [:name, :email, :location, :newsletter]
  FORM_LABEL = {
    :email => 'E-mail',
    :password => 'Password',
    :password_confirmation => 'Password confirmation',
    :tos => %(I have read and accept the <a href="/tos">Terms of Service</a>),
    :newsletter => 'I want to receive updates by email'
  }

  set_schema do
    primary_key :id

    varchar :name
    varchar :email
    varchar :crypt # hashed password

    varchar :location

    boolean :newsletter

    time :created_at
    time :updated_at

    foreign_key :company_id
  end

  one_to_many :cvs, :class => :CV, :join_table => 'cvs_users'
  belongs_to :company

  create_table unless table_exists?

  validations.clear
  validates do
    length_of :password, :minimum => 6, :allow_nil => true,
      :message => 'Minimum 6 characters'
    length_of :password, :maximum => 255, :allow_nil => true

    confirmation_of :password, :allow_nil => true
    presence_of :crypt

    presence_of :email
    uniqueness_of :email
    email_size = 'a@bc.de'.size
    length_of :email, :minimum => email_size,
      :message => "Minimum #{email_size} characters"
    format_of :email, :with => /^.+@..+\...+/
  end

  hooks.clear
  before_create{ self.created_at = Time.now }
  before_save{ self.updated_at = Time.now }

  after_create do
    unless company
      company = Company.new(
        :user_id => id,
        :founded => Date.today.year,
        :employees => '1-10')

      if company.valid?
        company.save
        self.company = company
        save
      else
        pp company.errors
        exit
      end
    end
  end

  def self.authenticate(hash)
    email = hash[:email] || hash['email']
    crypt = hash[:crypt] || encrypt(hash[:password] || hash['password'])

    User[:email => email, :crypt => crypt]
  end

  def self.encrypt(password)
    return unless password
    Digest::SHA1.hexdigest(password)
  end

  def self.new_encrypted(hash)
    password = hash.delete(:password)
    user = new(hash)
    user.crypt = encrypt(password)
    user
  end

  attr_accessor :password, :password_confirmation, :tos

  def profile_update(request)
    name, location = request[:name, :location]
    self.name = name
    self.location = location
  end

  def applied_to?(given_job)
    cvs.any? do |cv|
      cv.jobs.any? do |job|
        given_job.id == job.id
      end
    end
  end

  def cvs_sent
    job_cv = {}

    cvs.each do |cv|
      cv.jobs.each do |job|
        job_cv[job] = cv
      end
    end

    job_cv
  end

  def cvs_got
    cv_job = {}

    company.jobs.each do |job|
      job.cvs.each do |cv|
        cv_job[cv] = job
      end
    end

    cv_job
  end

  include FormField::Model

  # View

  def public_name
    name || email[/^(.*)@/, 1]
  end
end
