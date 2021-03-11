class Invoice::Manual < Invoice

  field :number, type: String

  scope :filter_by_number, ->(number) { where(number: number) }
end