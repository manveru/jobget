require 'db/init_database'
p :fill

conf = Configuration.for(:jobget)
init = InitDatabase

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
