require 'spec/helper'

describe 'User join' do
  behaves_like 'mechanize'

  def join_with(role, hash)
    click_link 'Join'
    click_link "Create #{role} account"
    form = page.form('/user/join')
    if tos = hash.delete(:tos)
      form.checkboxes.name('tos').check
    end
    form.set_fields hash
    submit form

    page
  end

  # Invalid joins

  email, password = 'applicant@bacon.com', 'applicant'

  should 'not perform join without confirmation of ToS' do
    join_with :applicant, :email => email,
      :password => password,
      :password_confirmation => password
    page.at('.error').inner_text.should =~ /Terms of Service not confirmed/
  end

  should 'not perform join without matching passwords' do
    join_with :applicant, :email => email,
      :password => password,
      :password_confirmation => password.succ
    page.at('.error').inner_text.should =~ /is not confirmed/
  end

  should 'not perform join with invalid email' do
    join_with :applicant, :email => 'foo@bar',
      :password => password,
      :password_confirmation => password
    page.at('.error').inner_text.should =~ /is invalid/
  end

  should 'not perform join with missing password' do
    join_with :applicant, :email => email
    page.at('.error').inner_text.should =~ /Minimum 6 characters/
  end

  should 'not perform join with short password' do
    join_with :applicant, :email => email,
      :password => 'foo',
      :password_confirmation => 'foo'
    page.at('.error').inner_text.should =~ /Minimum 6 characters/
  end

  should 'not perform join with short password' do
    join_with :applicant, :email => email,
      :password => 'foo',
      :password_confirmation => 'foo'
    page.at('.error').inner_text.should =~ /Minimum 6 characters/
  end

  # Valid join

  should 'perform join with correct values' do
    join_with :applicant, :email => email,
      :password => password,
      :password_confirmation => password,
      :tos => true
    page.at('.flash-good').inner_text.should =~ /Welcome to .+, you can start by filling your profile/
  end
end
