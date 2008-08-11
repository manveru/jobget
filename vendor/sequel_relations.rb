module SequelRelation
  def self.relations(&block)
    rm = RelationshipManager.new(&block)
    rm.finalize
  end

  class RelationshipManager
    TODO = {}

    def initialize(&block)
      instance_eval(&block)
    end

    def finalize
      TODO.keys.each do |model|
        model.create_table unless model.table_exists?
      end

      TODO.each do |model, instructions|
        instructions.each do |args|
          model.send(*args)
        end
      end

      return

      pp TODO

      TODO.keys.each do |model|
        puts "the #{model}"
        assoc = model.send(:association_reflections)
        assoc.each do |key, reflection|
          puts "  #{reflection[:type]} => #{key}"
        end
      end
    end

    def the(left_model, &block)
      @left = left_model
      TODO[@left] = []
      instance_eval(&block)
    end

    def belongs_to(model)
      todo :belongs_to, model.to_s.downcase.to_sym
    end

    def has_many(model)
      todo :create_join, model
      todo :many_to_many, model.to_s.downcase.pluralize.to_sym
    end

    def has_one(model)
      todo :belongs_to, model.to_s.downcase.to_sym
    end

    def todo(method, *args)
      TODO[@left] << [method, *args]
    end
  end
end
