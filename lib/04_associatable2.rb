require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method name do
      source_options = through_options
        .model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name
      foreign_key = "#{through_table}.#{source_options.foreign_key}"
      primary_key = "#{source_table}.#{source_options.primary_key}"

      result = DBConnection.execute(<<-SQL, self.send(through_options.primary_key))
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{foreign_key} = #{primary_key}
        WHERE
          #{through_table}.id = ?
      SQL

      source_options.model_class.new(result.first)
    end
  end
end
