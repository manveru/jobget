p :init

SequelRelation.relations do
  the Application do
    belongs_to User
    belongs_to Job
    belongs_to Company
    belongs_to Resume
  end

  the Job do
    belongs_to Company
    has_many Application
  end

  the Company do
    belongs_to User
    has_many Job
    has_one Logo
  end

  the Resume do
    belongs_to User
    has_many Application
  end

  the User do
    has_one Avatar
    has_one Company
    has_many Resume
  end

  the Avatar do
    belongs_to User
  end

  the Logo do
    belongs_to Company
  end
end
