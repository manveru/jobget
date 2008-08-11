require 'spec/helper'

describe 'Recruiter comes to site and wants to post a job' do
  behaves_like 'mechanize'

  name = Faker::Name::name
  email = Faker::Internet::email(name)
  password = 'recruiter'

  should 'sign up by trying to post a job' do
    click_link 'Post job'
    click_link "Don't have an account yet?"
    click_link "Create recruiter account"

    form = page.form('/user/join')

    form.set_fields :email => email,
      :password => password,
      :password_confirmation => password
    form.checkboxes.name('tos').check

    submit form

    page.at(:h2).inner_text.should == 'Post Job'
  end

  should 'decide to edit company first' do
    click_link 'Company'
    page.at(:h2).inner_text.should == 'Edit your company'
  end
end

# [2008-08-11 18:17:10] INFO   Dynamic request from 127.0.0.1: /
# [2008-08-11 18:17:11] INFO   Dynamic request from 127.0.0.1: /user/join
# [2008-08-11 18:17:13] INFO   Dynamic request from 127.0.0.1: /user/join?role=recruiter
# [2008-08-11 18:17:23] INFO   Dynamic request from 127.0.0.1: /user/join?role=recruiter
# [2008-08-11 18:17:25] INFO   Dynamic request from 127.0.0.1: /user/join?role=recruiter
# [2008-08-11 18:17:35] INFO   Dynamic request from 127.0.0.1: /user/join?role=recruiter
# [2008-08-11 18:17:35] INFO   Redirect to 'http://localhost:7000/user/read'
# [2008-08-11 18:17:35] INFO   Dynamic request from 127.0.0.1: /user/read
# [2008-08-11 18:17:38] INFO   Dynamic request from 127.0.0.1: /company/edit
# [2008-08-11 18:17:52] INFO   Dynamic request from 127.0.0.1: /company/edit
# [2008-08-11 18:17:54] INFO   Redirect to 'http://localhost:7000/company/edit'
# [2008-08-11 18:17:54] INFO   Dynamic request from 127.0.0.1: /company/edit
# [2008-08-11 18:17:55] INFO   Dynamic request from 127.0.0.1: /job/manage
# [2008-08-11 18:17:57] INFO   Dynamic request from 127.0.0.1: /job/post
# [2008-08-11 18:18:11] INFO   Dynamic request from 127.0.0.1: /job/post
# [2008-08-11 18:18:11] INFO   Redirect to 'http://localhost:7000/job/read/1-Some-job'
# [2008-08-11 18:18:11] INFO   Dynamic request from 127.0.0.1: /job/read/1-Some-job
# [2008-08-11 18:18:14] INFO   Dynamic request from 127.0.0.1: /user/read
# [2008-08-11 18:18:15] INFO   Dynamic request from 127.0.0.1: /application
# [2008-08-11 18:18:15] INFO   Dynamic request from 127.0.0.1: /job/browse
# [2008-08-11 18:18:17] INFO   Dynamic request from 127.0.0.1: /
