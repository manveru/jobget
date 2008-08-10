class User < Sequel::Model
  # self.raise_on_save_failure = false

  FORM = [:name, :email, :location, :newsletter, :role, :phone, :about]
  FORM_LABEL = {
    :email => 'E-mail',
    :password => 'Password',
    :password_confirmation => 'Password confirmation',
    :tos => %(I have read and accept the <a href="/tos">Terms of Service</a>),
    :newsletter => 'I want to receive updates by email',
    :location => 'Location',
    :name => 'Name',
    :phone => 'Phone number',
    :about => 'About me',
  }

  set_schema do
    primary_key :id

    varchar :name
    varchar :email
    varchar :crypt, :size => 40 # hashed password

    varchar :role, :size => 9 # "applicant" | "recruiter" | "admin"

    # If a user has sent the forgot form this will contain a hashed value that
    # is sent to the email address.
    # The link contained in the email will log the user in by using this hash
    # so he can change the password.
    varchar :reset_hash, :size => 40

    varchar :location
    varchar :phone
    varchar :about

    boolean :newsletter

    time :created_at
    time :updated_at

    foreign_key :company_id
    foreign_key :avatar_id
  end

  one_to_many :resumes
  belongs_to :avatar # has_one
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

  # Reset Password

  include Ramaze::Helper::Link

  def reset_password
    link = create_hash_link
    mail_text = format_mail :forgot_password,
                            :forgot_link => link,
                            :name => public_name

    Ramaze::EmailHelper.send email,
      "Password reset for #{email}",
      mail_text
  end

  def format_mail(name, variables_given)
    filename = "mail/#{name}"
    erb = ERB.new(File.read(filename))
    erb.filename = filename

    @config = Configuration.for(:jobget)
    variables_given.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    erb.result(binding)
  end

  def create_hash_link
    c = Configuration.for(:jobget)
    hash = [email, Time.now.to_f, rand].join
    hash = Digest::SHA1.hexdigest(hash)

    self.reset_hash = hash
    save

    link = R(UserController, :forgot_login, :email => email, :hash => hash)
    link = URI(link)
    link.host = c.domain
    link.scheme = 'http'
    link
  end

  # Modify Profile

  def profile_update(request)
    self.name, self.location, self.phone, self.about =
      request[:name, :location, :phone, :about]

    if file = request[:avatar]
      update_avatar(file)
    end

    if valid?
      save
      return :good => "Profile updated"
    else
      return :bad => errors.inspect
    end
  rescue TypeError => ex
    Ramaze::Log.error(ex)
    return :bad => "The submitted image cannot be processed."
  end

  def update_avatar(file)
    if avatar = Avatar.store(file, public_name, :user_id => id)
      self.avatar = avatar
    end
  end

  # TODO: produce performant SQL
  def applied_to?(given_job)
    resumes.any? do |resume|
      resume.jobs.any? do |job|
        given_job.id == job.id
      end
    end
  end

  # TODO: produce performant SQL
  def visible_to?(user)
    return true if user.admin? or user.id == id

    resumes.any? do |resume|
      resume.jobs.any? do |job|
        job.company.user.id == user.id
      end
    end
  end

  def resumes_sent
    job_resume = {}

    resumes.each do |resume|
      resume.jobs.each do |job|
        job_resume[job] = resume
      end
    end

    job_resume
  end

  def resumes_got
    resume_job = {}

    company.jobs.each do |job|
      job.resumes.each do |resume|
        resume_job[resume] = job
      end
    end

    resume_job
  end

  include FormField::Model

  # View

  def public_name
    name || email[/^(.*)@/, 1]
  end

  def recruiter?
    %w[recruiter admin].include? role
  end

  def applicant?
    %w[applicant admin].include? role
  end

  def admin?
    role == 'admin'
  end

  # Links

  include ModelLink

  def link_ref
    [id, *public_name.scan(/\w+/)].join('-').downcase
  end
end
