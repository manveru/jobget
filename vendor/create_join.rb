module Sequel
  class Model
    def self.create_join(to, name = "#{table_name}_#{to.table_name}")
      from = self
      from_key = "#{from.table_name.to_s.singularize}_id"
      to_key = "#{to.table_name.to_s.singularize}_id"

      db.create_table! name do
        primary_key :id
        foreign_key from_key, :class => from
        foreign_key to_key, :class => to
      end
    end
  end
end
