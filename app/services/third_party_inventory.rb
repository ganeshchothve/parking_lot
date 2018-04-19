module ThirdPartyInventory
  def self.hold_on_third_party_inventory(project_unit)
    third_party_inventory_response = {}
    third_party_inventory_response_code = 200
    third_party_inventory_response = {code: 'hold', project_unit: {status: 'hold'}}
    third_party_inventory_response_code = 200

    # if Rails.env.development?
    #   third_party_inventory_response = {code: 'hold', project_unit: {status: 'hold'}}
    #   third_party_inventory_response_code = 200
    #   # third_party_inventory_response = {code: 'hold', project_unit: { status: 'hold' } }
    #   # third_party_inventory_response_code = 200
    #   # third_party_inventory_response = {code: 'not_available', project_unit: {status: 'not_available'}}
    #   # third_party_inventory_response_code = 200
    # elsif Rails.env.staging?
    #   # TODO: hit sandbox third_party_inventory
    #   third_party_inventory_response = {code: 'hold', project_unit: {status: 'hold'}}
    #   third_party_inventory_response_code = 200
    # elsif Rails.env.production?
    #   # TODO: hit production third_party_inventory
    #   third_party_inventory_response = {code: 'hold', project_unit: {status: 'hold'}}
    #   third_party_inventory_response_code = 200
    # end

    return third_party_inventory_response, third_party_inventory_response_code
  end

  # Takes the third_party_inventory response json / xml & applies it to the model attributes
  def self.map_third_party_inventory(project_unit, third_party_inventory_response)
    # project_unit.attributes = third_party_inventory_response[:project_unit] #TODO: modify this based on third_party_inventory's reposnse json / xml
  end
end
