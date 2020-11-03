class NameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    unless value.match(/\A[a-z0-9\s]+\z/i)
      record.errors[attribute] << (options[:message] || "can contain only alphanumeric letters and spaces")
    end
  end

end
