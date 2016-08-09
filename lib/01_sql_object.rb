require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns unless @columns.nil?
    db_info = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns = db_info.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column_name|
      define_method "#{column_name}" do
        attributes[column_name]
      end

      define_method "#{column_name}=" do |value|
        attributes[column_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results_array = []
    results.each do |result|
      results_array << self.new(result)
    end
    results_array
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    return nil if result.empty?

    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym

      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end

      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def columns
    @columns ||= self.class.columns
  end

  def table_name
    @table_name ||= self.class.table_name
  end

  def attribute_values
    columns.map { |column_name| send(column_name) }
  end

  def insert
    col_names = columns[1..-1].join(", ")
    question_marks = ( ["?"] * (columns.length - 1) ).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_string = columns[1..-1].map { |col_name| "#{col_name} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values[1..-1], self.id)
      UPDATE
        #{table_name}
      SET
        #{set_string}
      WHERE
        id = ?
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end


class Cat < SQLObject
  finalize!
end
