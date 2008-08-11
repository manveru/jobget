module InitDatabase
  module_function

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
