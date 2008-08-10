module InitDatabase
  module_function

  def create_tables(*models)
    models.each{|model| model.create_table! }
  end

  def create_joins(hash)
    hash.each do |from, to|
      from.create_join(to)
    end
  end

  def create_admin(c)
    hash = {
      :email    => c.email,
      :name     => c.name,
      :password => c.password,
      :location => c.location,
      :about    => c.about,
      :phone    => c.phone,
      :role     => 'admin',
    }

    admin = User.new_encrypted(hash)
    check_save(admin)
    admin
  end

  def create_user(hash = {})
    name     = hash[:name]  || Faker::Name.name
    email    = hash[:email] || Faker::Internet.email(name)
    about    = hash[:about] || Faker::Lorem.paragraphs(3).join("\n")
    phone    = hash[:phone] || Faker::PhoneNumber.phone_number

    role     = hash[:role]     || 'recruiter'
    password = hash[:password] || 'letmein'

    location = [:uk_country, :uk_postcode, :uk_county, :street_address]
    location = location.map{|sym| Faker::Address.send(sym) }.join(', ')
    location = hash[:location] || location

    user = User.new_encrypted(:name => name,
                              :email => email,
                              :password => password,
                              :phone => phone,
                              :about => about,
                              :location => location,
                              :role => role)
    check_save(user)
  end

  def create_job(company)
    job = Job.new
    job.title = Faker::Company.catch_phrase
    job.featured = 0.42 > rand
    job.public = 0.42 > rand
    job.open = 0.42 > rand
    job.contract = 'Full-time'
    job.salary_interval = 'Hour'
    job.salary_low = rand(500)
    job.salary_high = job.salary_low + rand(1000)
    job.starts_at = Date.today + rand(356)
    job.location = Faker::Address::city

    job.text = Faker::Lorem.paragraphs(3 + rand(3)).join("\n")
    job.skills = Array.new(rand(6)){ Faker::Company.bs }.join("\n")

    job.company_id = company.id

    check_save(job)
    company.add_job(job)
  end

  def check_save(obj)
    if obj.valid?
      obj.save
    else
      pp obj.errors
      exit 1
    end
  end
end

conf = Configuration.for(:jobget)
init = InitDatabase

init.create_tables Job, Company, User, Resume, Logo
init.create_joins(Job => User,
                  Company => Job,
                  Resume => User,
                  Resume => Job)

admin = init.create_admin(conf.admin)

init.create_user :name => 'Recruiter', :role => 'recruiter',
  :password => 'recruiter', :email => 'recruiter@recruiter.com'
init.create_user :name => 'Applicant', :role => 'applicant',
  :password => 'applicant', :email => 'applicant@applicant.com'

6.times{ init.create_user }

Company.each do |company|
  (1 + rand(10)).times do
    init.create_job(company)
  end

  next if company.text
  company.text = Faker::Lorem.paragraph
  company.name = Faker::Company.name

  init.check_save(company)
end

__END__

file = 'public/grey.png'
req = {
  :title => file,
  :file => {
    :type => `file -bi #{file}`.strip,
    :tempfile => File.open(file),
  }
}

begin
  resume = Resume.from_request(admin, req)
rescue Any2Text::CannotConvert => ex
  puts ex
  next
end

init.check_save(resume)

__END__

Dir['res/Resume.*'].each do |resume|
  req = {
    :title => resume,
    :file => {
      :type => `file -bi #{resume}`.strip,
      :tempfile => File.open(resume),
    }
  }
  pp req

  begin
    resume = Resume.from_request(admin, req)
  rescue Any2Text::CannotConvert => ex
    puts ex
    next
  end

  check_save[resume]
end
