require 'autoinc'
module NumberIncrementor
  extend ActiveSupport::Concern
  #include Mongoid::Autoinc

  included do
    field :number, type: Integer
    #increments :number

    scope :filter_by_number, ->(number) { where(number: number) }

    alias_method :orig_number, :number

    def number
      (self.class.const_defined?('NUMBER_PREFIX') ? self.class.const_get('NUMBER_PREFIX') : '') + orig_number.to_s.rjust(6, '0')
    end
  end
end
