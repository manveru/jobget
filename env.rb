Configuration.for :jobget do
  title 'Macheads'
  domain 'macheads.co.uk'

  # :live => DB specified by db below, no init
  # :dev  => DB sqlite in memory, init executed
  # Ramaze::Global.mode = :dev
  db 'sqlite://db/jobget.sqlite' # DB to use in live mode

  admin do
    email 'm.fellinger@gmail.com'
    name "Michael Fellinger"
    password 'letmein'
    location 'Tokyo, Japan'
    about 'The admin. Got root'
    phone '777 777 777' # don't call or the world will implode
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

handle_error = Ramaze::Dispatcher::Error::HANDLE_ERROR
handle_error.clear
handle_error.merge!(
  Object                  => [500, '/error/internal_server_error'],
  Ramaze::Error::NoAction => [404, '/error/not_found']
)
