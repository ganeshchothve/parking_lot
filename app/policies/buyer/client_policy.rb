class Buyer::ClientPolicy < ClientPolicy
  def switch_client?
    false
  end
end
