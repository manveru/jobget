class Application < Sequel::Model
  set_schema do
    primary_key :id

    time :created_at
    time :updated_at

    foreign_key :company_id
    foreign_key :resume_id
    foreign_key :user_id
    foreign_key :job_id
  end

  before_create{ self.created_at = Time.now }
  before_save{ self.updated_at = Time.now }
end
