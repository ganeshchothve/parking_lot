class Car
  include Mongoid::Document
  include Mongoid::Timestamps

  COLORS = ['red', 'yellow', 'white', 'green', 'black']
  field :color, type: String
  field :reg_no, type: String

  has_one :ticket

  validates :reg_no, presence: true, uniqueness: { case_sensitive: false }
  validates :color, presence: true, inclusion: { in: COLORS }

end
