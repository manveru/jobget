module JobGet
  class User < Sequel::Model
    FORM_LABEL = {
      :tos        => %(I have read and accept the <a href="/tos">Terms of Service</a>),
      :role       => 'User Role',
      :name       => 'Name',
      :phone      => 'Phone number',
      :about      => 'About me',
      :email      => 'E-mail',
      :location   => 'Location',
      :newsletter => 'I want to receive updates by email',
      :avatar     => 'Avatar (png, jpeg, gif)',

      :password   => 'Password',
      :password_confirmation => 'Password confirmation',
    }

    FORM_UPDATE =
      FORM_LABEL.keys - [
        :email, :role, :tos, :password, :password_confirmation, :avatar]
    FORM_JOIN = (FORM_LABEL.keys - FORM_UPDATE) + [:newsletter]

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

      format_of :role, :with => /\A(admin|recruiter|applicant)\Z/

      length_of :name, :minimum => 2, :allow_nil => true,
        :message => 'Minimum 2 characters'
      length_of :name, :maximum => 50, :allow_nil => true,
        :message => 'Maximum 50 characters'
    end

    before_create(:created_at){ self.created_at = Time.now }
    before_save(:updated_at){ self.updated_at = Time.now }

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

      link = Users.r(:forgot_login, :email => email, :hash => hash)
      link.host = c.domain
      link.scheme = 'http'
      link
    end

    # Modify Profile

    def self.prepare(request)
      user = new(request.subset(*FORM_JOIN))
      user.errors.add(:role, 'Role not allowed') if user.role == 'admin'
      user
    end

    def joins
      self.crypt = self.class.encrypt(password)

      return nil unless valid? # fail

      save and return self if self.tos

      errors.add(:tos, 'Terms of Service not confirmed')
      return nil # fail
    end

    def password_update(request)
      self.password, self.password_confirmation =
        request[:password, :password_confirmation]
      self.crypt = self.class.encrypt(self.password)

      return self if valid?
    end

    def profile_update(request)
      set_values request.subset(*FORM_UPDATE)

      file = request[:avatar]
      update_avatar(file) if file

      if valid?
        save
        return :good => "Profile updated"
      end
    rescue TypeError => ex
      Ramaze::Log.error(ex)
      Ramaze::Log.debug(file)
      errors.add :avatar, "The submitted image cannot be processed."
      nil
    end

    def update_avatar(file)
      if new_avatar = Avatar.store(file, public_name, :user_id => id)
        avatar.destroy if avatar
        self.avatar = new_avatar
      end
    rescue ArgumentError => ex
      return if ex.message =~ /empty tempfile/i
      Ramaze::Log.error(ex)
    end

    def applied_to?(given_job)
      Application[:user_id => id, :job_id => given_job.id]
    end

    def visible_to?(given_user)
      return true if given_user.admin? or given_user.id == id

      Application[:company_id => given_user.company.id, :user_id => id]
    end

    def resumes_sent
      Application.filter(:resume_id => resumes.map{|r| r.id })
    end

    def resumes_got
      Application.filter(:company_id => company.id)
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

    def to(action, *args)
      Users.r(action, link_ref, *args)
    end

    def link_ref
      [id, *public_name.scan(/\w+/)].join('-').downcase
    end

    def self.create_admin
      return if self[:role => 'admin']

      config = JobGet.options.admin

      hash = {
        :email    => config.email,
        :name     => config.name,
        :password => config.password,
        :location => config.location,
        :about    => config.about,
        :phone    => config.phone,
        :role     => 'admin',
      }

      admin = new_encrypted(hash)
      admin.save
      pp admin
      return admin
    end
  end
end
