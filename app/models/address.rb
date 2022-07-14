class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  CITY = ["Gwalior","Jabalpur","Ujjain","Malegaon","Nanded","Kolhapur","Mumbai","Navi Mumbai","Thane","Akola","Nagpur","Pune","Solapur","Bhubaneswar","Cuttack","Chandigarh","Ludhiana","Sangrur","Amritsar","Jalandhar","Ajmer","Kota","Jaipur","Bikaner","Jodhpur","Coimbatore","Erode","Salem","Madurai","Tirunelveli","Agra","Jhansi","Mainpuri","Mathura","Allahabad","Ghazipur","Varanasi","Bareilly","Hardoi","Kheri","Meerut","Moradabad","Saharanpur","Ballia","Gorakhpur","Banda","Kanpur","Faizabad","Ghaziabad","Lucknow","Dehradun","Kolkata","Asansol","Burdwan","Howrah","Midnapore","Guwahati","Hyderabad","Jamnagar","Delhi","Patna","Raipur","Rajkot","Vijayawada","Surat","Vadodara","Faridabad","Gurgaon","Jammu","Dhanbad","Ranchi","Bangalore","Belgaum","Gulbarga","Mangalore","Mysore","Bhopal","Amravati","Nashik","Aligarh","Ahmedabad","Chennai","Visakhapatnam","Indore","Pimpri-Chinchwad","Kalyan-Dombivali","Vasai-Virar","Srinagar","Aurangabad","Thiruvananthapuram","Hubballi-Dharwad","Tiruchirappalli","Tiruppur","Bareily","Mira-Bhayandar","Warangal","Guntur","Bhiwandi","Noida","Jamshedpur","Bhilai","Firozabad","Kochi","Nellore","Bhavnagar","Durgapur","Loni","Siliguri","Ulhasnagar","Sangli-Miraj & Kupwad","Ambattu"]

  field :one_line_address, type: String
  field :address1, type: String
  field :address2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :address_type, type: String, default: 'work' #TODO: Must be personal, work etc
  field :selldo_id, type: String

  belongs_to :booking_portal_client, class_name: 'Client', optional: true
  belongs_to :addressable, polymorphic: true, optional: true

  #validates :address_type, presence: true
  #validate :check_presence, if: Proc.new{ |address| address.addressable.class.to_s != 'Project' }

  enable_audit({
    audit_fields: [:city, :state, :country, :address_type, :selldo_id],
    associated_with: ["addressable"]
  })

  def name_in_error
    address_type
  end

  def ui_json
    to_json
  end

  def to_sentence
    return self.one_line_address if self.one_line_address.present?
    str = "#{self.address1}"
    str += " #{self.address2}," if self.address2.present?
    str += " #{self.city}," if self.city.present?
    str += " #{self.state}," if self.state.present?
    str += " #{self.country}," if self.country.present?
    str += " #{self.zip}" if self.zip.present?
    str.strip!
    str.present? ? str : "-"
  end

  def to_s
    to_sentence
  end

  def check_presence
    errors.add(:base, 'address is invalid') unless as_json(only: [:address1, :city, :state, :country, :zip]).values.all?(&:present?) || one_line_address.present?
  end
end
