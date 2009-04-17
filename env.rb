require 'rubygems'
require 'ramaze'

module JobGet
  include Ramaze::Optioned

  options.dsl do
    o 'Site title', :title,
      'JobGet'

    o 'Site domain', :domain,
      'jobget.ramaze.net'

    sub :admin do
      o 'email address',    :email,    'm.fellinger@gmail.com'
      o 'Full name',        :name,     'Michael Fellinger'
      o 'Default password', :password, 'letmein'
      o 'Location',         :location, 'Tokyo, Japan'
      o 'About you',        :about,    'The admin. Got root!'
      o 'Phone number',     :phone,    '777 777 777'
    end

    sub :mail do
      o 'SMTP Server', :smtp_server,
        'localhost'
      o 'HELO Domain', :smtp_helo_domain,
        domain
      o 'SMTP Username', :smtp_username,
        'user'
      o 'SMTP Password', :smtp_password,
        'pass'
      o 'Address of sender', :sender_address,
        "no-reply@#{domain}"

      # Following are optional, but you might want to set them
      o 'BCC Addresses', :bcc_addresses,
        ["admin@#{domain}"]
      o 'ID generating block', :id_generator,
        lambda{ "<#{Time.now.to_i}@#{smtp_helo_domain}>" }
      o 'Displayed address of sender', :sender_full,
        "MailBot <#{sender_address}>"
      o 'Type of authentication for SMTP', :smtp_auth_type,
        :login
      o 'Port of the SMTP Server', :smtp_port,
        25
      o 'Prefix this to every subject', :subject_prefix,
        "[#{title}]"
    end
  end
end
