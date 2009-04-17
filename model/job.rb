module JobGet
  class Job < Sequel::Model
    FORM = [
      :title, :text, :skills,
      :internal, :contract, :location,
      :salary_interval, :salary_low, :salary_high,
      :public, :open
    ]

    FORM_LABEL = {
      :title => 'Job Title',
      :skills => 'List of skills (one line per skill)',
      :internal => 'Internal ID',
      :location => 'Job Location',
      :contract => 'Contract Type',
      :salary_interval => 'Salary Interval',
      :salary_low => 'Salary Low',
      :salary_high => 'Salary High',
      :public => 'Publicly visible',
      :open => 'Open for applications',
      :text => 'Job Description',
    }

    CONTRACTS = %w[ Premament Freelance ]
    SALARIES = %w[Hourly Daily WeeklyMonthly Yearly]

    set_schema do
      primary_key :id

      varchar :title
      string :text
      string :skills

      varchar :internal
      varchar :contract
      varchar :location

      varchar :salary_currency
      varchar :salary_interval
      integer :salary_low
      integer :salary_high

      time :created_at
      time :updated_at
      time :expires_at

      date :starts_at

      boolean :featured, :default => false
      boolean :public, :default => true
      boolean :open, :default => true

      foreign_key :company_id
    end

    validations.clear
    validates do
      numericality_of :salary_low, :only_integer => true, :allow_nil => true
      numericality_of :salary_high, :only_integer => true, :allow_nil => true

      format_of :title, :with => /\A[^\n\r]+\z/, :message => 'May not contain newlines'
      presence_of :company_id
    end

    before_create('update created_at'){ self.created_at = Time.now }
    before_save('update updated_at'){ self.updated_at = Time.now }
    before_destroy 'cleanup of Applications for this Job' do
      applications.each do |app|
        app.destroy
      end
    end

    def self.latest(n = nil)
      f = available.filter(:featured => false)
      n ? f.limit(n) : f
    end

    def self.featured(n = nil)
      f = available.filter(:featured => true)
      n ? f.limit(n) : f
    end

    def self.available(n = nil)
      f = filter(:open => true, :public => true).
            eager(:company).
            order(:updated_at.desc)
      n ? f.limit(n) : f
    end

    def available?
      open and public
    end

    def self.search(category, *words)
      case category
      when /any/
        search_any(*words)
      when /job/
        search_job(*words)
      when /skill/
        search_skill(*words)
      when /company/
        search_company(*words)
      else
        raise(ArgumentError, "No search for this category available")
      end
    end

    def self.search_any(*words)
      terms = words.map{|word| "%#{word}%" }
      available.filter([:title, :text, :skills].sql_string_join.like(*terms))
    end

    def self.search_job(*words)
      terms = words.map{|word| "%#{word}%" }
      available.filter([:title, :text, :skills].sql_string_join.like(*terms))
    end

    def self.search_skill(*words)
      terms = words.map{|word| "%#{word}%" }
      available.filter(:skills.like(*terms))
    end

    def self.search_company(*words)
      Company.search(*words)
    end

    def related(n = 5)
      words = title.to_s.scan(/\w+/)
      words += skills.to_s.scan(/\w+/)
      Job.search(*words).filter(~{:id => id})
    end

    # View

    require 'ramaze/helper/formatting'
    include Ramaze::Helper::Formatting

    def salary
      s_low = number_format(salary_low)
      s_high = number_format(salary_high)
      "#{s_low} ~ #{s_high} / #{salary_interval}"
    end

    def preview
      text.to_s.lines.first(2).join("<br />\n")[0..255] + '...'
    end

    def updated_formatted
      updated_at.strftime('%Y-%m-%d')
    end

    def created_formatted
      created_at.strftime('%Y-%m-%d')
    end

    def skill_list
      skills.to_s.split(/[\n\r]+/)
    end

    # Links

    include ModelLink

    # Forms

    def self.from_request(request)
      instance = new
      instance.set_values(request.subset(*FORM)) if request.post?
      instance
    end

    include FormField::Model
  end
end
