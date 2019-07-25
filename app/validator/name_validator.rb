class NameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if value.match(/[^\w\s]/)
      record.errors[attribute] << (options[:message] || "can contain only alphabets and spaces")
    end
  end

end