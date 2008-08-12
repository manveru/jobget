require 'spec/helper'

describe 'Recruiter signs up and posts a job' do
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

  should 'be able to edit company' do
    click_link 'Company'
    page.at(:h2).inner_text.should == 'Edit your company'

    form = page.form('/company/edit')

    form.set_fields :name => Faker::Company::name,
      :founded => '1990',
      :employees => '11-50',
      :text => Faker::Lorem::paragraphs(3).join("\n")

    submit form
  end

  should 'be able to post job' do
    click_link 'Post job'
    page.at(:h2).inner_text.should == 'Post Job'

    form = page.form('/job/post')

    form.set_fields :title => 'Ruby Developer',
      :internal => 'ruby_dev_1',
      :location => 'Tokyo, Japan',
      :contract => 'Freelance',
      :salary_interval => 'Daily',
      :salary_low => '20000',
      :salary_high => '30000',
      :skills => "Ruby\nRamaze\nLinux",
      :text => "Need ASAP"

    form.checkboxes.name('public').check
    form.checkboxes.name('open').check

    submit form

    page.at(:h2).inner_text.should == 'Ruby Developer'
  end

  should 'head to main page and see job listed as latest' do
    click page.links.first
    (page/:h2).map{|h2| h2.inner_text }.should == %w[Featured Latest]

    link = page.at('.latest/.job/a')
    link[:href].should == "/job/read/1-Ruby-Developer"
    link.inner_text.should == 'Ruby Developer'
  end
end
