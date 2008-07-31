require 'logger'
db = Sequel.sqlite :logger => Logger.new($stdout)

require 'vendor/create_join'
require 'vendor/form_field'

acquire 'model/*.rb'

[Job, Company, User, CV].each do |model|
  model.create_table!
end

Job.create_join User
Company.create_join Job
CV.create_join User
CV.create_join Job

conf_admin = Configuration.for(:jobget).admin
admin = User.new_encrypted(:email => conf_admin.email,
                           :password => conf_admin.password,
                           :location => conf_admin.location)
if admin.valid?
  admin.save
else
  pp admin.errors
  exit
end

5.times do
  name = Faker::Name.name
  email = Faker::Internet.email(name)

  user = User.new_encrypted(:name => name,
                            :email => email,
                            :password => 'letmein')
  if user.valid?
    user.save
  else
    p user.errors
    exit
  end
end

100.times do
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

  text = Faker::Lorem.paragraphs
  text << ''
  (3 + rand(10)).times do
    text << "* #{Faker::Company.bs}"
  end
  job.text = text.join("\n")

  company = Company.all.sort_by{ rand }.first
  job.company_id = company.id

  if job.valid?
    job.save
    company.add_job(job)
  else
    pp job.errors
    exit
  end
end

Company.each do |company|
  company.text = Faker::Lorem.paragraph
  company.name = Faker::Company.name
  company.save
end
