DB = Sequel.sqlite # :logger => Logger.new($stdout)

acquire 'model/*.rb'

[Job, Company, User, Resume].each do |model|
  model.create_table!
end

Job.create_join User
Company.create_join Job
Resume.create_join User
Resume.create_join Job

check_save = lambda{|obj|
  obj.valid? ? obj.save : (pp obj.errors; exit(1))
}

conf_admin = Configuration.for(:jobget).admin
admin = User.new_encrypted(:email    => conf_admin.email,
                           :name     => conf_admin.name,
                           :password => conf_admin.password,
                           :location => conf_admin.location)
check_save[admin]

(6 - User.count).times do
  name = Faker::Name.name
  email = Faker::Internet.email(name)

  user = User.new_encrypted(:name => name,
                            :email => email,
                            :password => 'letmein')
  check_save[user]
end

(100 - Job.count).times do
  job = Job.new
  job.title = Faker::Company.catch_phrase
  job.featured = 0.42 > rand
  job.public = 0.42 > rand
  job.open = 0.42 > rand
  job.contract = 'Full-time'
  job.salary_interval = 'Year'
  job.salary_low = rand(10_000_000)
  job.salary_high = job.salary_low + rand(10_000_000)
  job.starts_at = Date.today + rand(356)
  job.location = Faker::Address::city

  job.text = Faker::Lorem.paragraphs(3 + rand(3)).join("\n")
  job.skills = Array.new(rand(6)){ Faker::Company.bs }.join("\n")

  company = Company.all.sort_by{ rand }.first
  job.company_id = company.id

  check_save[job]
  company.add_job(job)
end

Company.each do |company|
  next if company.text
  company.text = Faker::Lorem.paragraph
  company.name = Faker::Company.name
  company.save
end

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
