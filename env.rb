Configuration.for :jobget do
  title 'Macheads'
  domain 'macheads.co.uk'

  admin do
    email 'm.fellinger@gmail.com'
    name "Michael Fellinger"
    password 'letmein'
    location 'Tokyo, Japan'
  end

  mail do
    # These settings should be changed
    smtp_server      "localhost" # "smtp.#{domain}"
    smtp_helo_domain domain
    smtp_username    nil # "user"
    smtp_password    nil # "pass"
    sender_address   "no-reply@#{domain}"

    # Optional, set to defaults
    # NOTE: keep them in sync with the options in contrib/email
    bcc_addresses  [ "admin@#{domain}" ]
    id_generator   lambda{ "<#{Time.now.to_i}@#{smtp_helo_domain}>" }
    sender_full    "MailBot <#{sender_address}>"
    smtp_auth_type nil # :login
    smtp_port      25
    subject_prefix "[#{title}]"
  end
end

m = Configuration.for(:jobget).mail

Ramaze::EmailHelper.trait.each do |key, value|
  Ramaze::EmailHelper.trait key => m.send(key)
end
