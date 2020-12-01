class CopyErrorsFromChildValidator < ActiveModel::EachValidator
  def validate_each(parent, children, value)
    invalid_child = false
    if value.is_a? Array
      value.reject(&:marked_for_destruction?).each do |child|
        if child.invalid?
          parent.errors.add :base, "#{child.model_name.human} (#{child.try(:name_in_error) || parent.try(:name_in_error)}) errors - #{child.errors.to_a.to_sentence}"
          invalid_child = true
        end
      end
    elsif value.invalid?
      parent.errors.add :base, "#{value.model_name.human} #{ value.respond_to?(:name_in_error) ? ('(' + value.try(:name_in_error) + ')') : '' } errors - #{value.errors.to_a.to_sentence}"
      invalid_child = true
    end

    if invalid_child
      parent.errors[children].delete_if {|msg| msg == 'is invalid'}
    end
  end
end
