require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.downcase << "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = "#{name}_id".to_sym
    @primary_key = :id
    @class_name = name.to_s.camelcase

    options.each do |attr_name, value|
      instance_variable_set("@#{attr_name}", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = "#{self_class_name.underscore}_id".to_sym
    @primary_key = :id
    @class_name = name.to_s.singularize.camelcase

    options.each do |attr_name, value|
      instance_variable_set("@#{attr_name}", value)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method name do
      foreign_key = self.send(options.foreign_key)
      options
        .model_class
        .where(options.primary_key => foreign_key)
        .first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = options

    define_method name do
      primary_key = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => primary_key)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
