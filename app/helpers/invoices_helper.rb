module InvoicesHelper
  def available_events record
    record.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end
end
