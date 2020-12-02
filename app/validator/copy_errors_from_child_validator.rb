class CopyErrorsFromChildValidator < ActiveModel::EachValidator
  def validate_each(parent, children, value)
    invalid_child = false
    if value.is_a? Array
      value.reject(&:marked_for_destruction?).each do |child|
        if child.invalid?
          add_error_on_parent(parent, child)
          invalid_child = true
        end
      end
    elsif value.invalid?
      add_error_on_parent(parent, value)
      invalid_child = true
    end

    if invalid_child
      parent.errors[children].delete_if {|msg| msg == 'is invalid'}
    end
  end

  def add_error_on_parent(parent, child)
    parent.errors.add :base, "#{child.model_name.human} #{ child.respond_to?(:name_in_error) ? ('(' + child.try(:name_in_error) + ')') : '' } errors - #{child.errors.to_a.uniq.to_sentence}"
  end
end
