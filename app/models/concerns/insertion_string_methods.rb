module InsertionStringMethods
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    # Insertion strings are user defined variables that are used in templates - email, sms, etc.
    # These variables are coded names of your rails model. Whenever we send an email or sms using templates, all insertion strings present in the body are replaced with its respective values.
    # So basically it specifies which values to pick from a record to replace with
    # insertion string variables are coded like - {{ variable_name }}
    #
    def insertion_strings level, traversed_classes=[]
      fields = self.fields.collect{|k, _v| {id: k, text: k.titleize}}
      fields = fields.reject do |hash|
        ["_id", "updated_at"].include?(hash[:id])
      end
      if self.custom_fields_enabled?
        fields += self.available_custom_fields.collect{|c| { id: c.name, text: c.display_name } }
      end
      traversed_classes << self.to_s
      if  level > 0 && traversed_classes.exclude?("User")
        traversed_classes << "User"
        user_fields = User.insertion_strings(level - 1, traversed_classes)
      end
      fields
    end
  end
  module InstanceMethods
    def get_binding
      binding
    end

    # format for insertion strings should be Klass.(AssociationKlass|method)+
    # example1 contacts.address.address => self.contacts.addresses.collect(&:address).to_sentence
    #
    def parse_insertion_string insertion_string, object = nil
      object ||= self
      value = (get_insertion_values(insertion_string, object) rescue []).to_sentence
      class_name = self.class.fields[insertion_string].try(:type)
      if value.present?
        case class_name.to_s
        when "Time"
          value = Time.parse(value).strftime("%I:%M %p")
        when "Date"
          value = Date.parse(value).strftime("%d/%m/%Y")
        when "DateTime"
          value = DateTime.parse(value).strftime("%d/%m/%Y %I:%M %p")
        end
      end
      value
    end

    def get_insertion_values insertion_string, object
      values = []
      if object.present?
        if insertion_string.include?(".")
          method_name = insertion_string.split(".", 2).first
          insertion_string = insertion_string.split(".", 2).last
          object = object.send(method_name.to_sym)
          if object.class.include?(Enumerable) && object.class != Hash
            object.each do |obj|
              values.push(get_insertion_values(insertion_string, obj))
            end
          else
            values.push(get_insertion_values(insertion_string, object))
          end
        else
          values << ( object.respond_to?(insertion_string) ? object.send(insertion_string) : object[insertion_string] )
        end
      end
      values.flatten.compact
    end
  end
end
