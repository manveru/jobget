module JobGet
  class Company < Sequel::Model
    include ModelLink
    include FormField::Model

    FORM_LABEL = {
      :name      => 'Company name',
      :founded   => 'Year founded',
      :text      => 'Company description',
      :employees => 'No. of Employees',
      :logo      => 'Logo (png, jpeg, gif)',
    }

    FORM_UPDATE = FORM_LABEL.keys - [:logo]

    set_schema do
      primary_key :id

      varchar :name
      integer :founded
      varchar :employees
      string :text

      boolean :show_logo, :default => false

      foreign_key :user_id
      foreign_key :logo_id
    end

    validations.clear
    validates do
      length_of :founded, :is => 4
      numericality_of :founded, :only_integer => true
      uniqueness_of :name
      format_of :employees, :with => /^\d+(\+|-\d+)$/
    end

    def self.search(*words)
      terms = words.map{|word| "%#{word}%" }
      filter :name.like(*terms)
    end

    def profile_update(request)
      set_values request.subset(*FORM_UPDATE)

      if file = request[:logo]
        update_logo(file)
      end

      if valid?
        save
        return :good => "Company updated"
      else
        return :bad => errors.inspect
      end
    rescue TypeError => ex
      Ramaze::Log.error(ex)
      return :bad => "The submitted image cannot be processed."
    end

    def update_logo(file)
      if new_logo = Logo.store(file, id, :company_id => id)
        self.show_logo = true

        logo.destroy if logo
        self.logo = new_logo
      end
    rescue ArgumentError => ex
      return if ex.message =~ /empty tempfile/i
      Ramaze::Log.error(ex)
    end

    # Links

    def to_search
      R(SearchController, :q => name, :only => :company)
    end
  end
end
