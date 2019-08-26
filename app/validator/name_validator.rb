class NameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    unless value.match(/\A[a-z\s]+\z/i)
      record.errors[attribute] << (options[:message] || "can contain only alphabets and spaces")
    end
  end

end
