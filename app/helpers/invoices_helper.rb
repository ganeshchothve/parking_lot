module InvoicesHelper
  def available_events invoice
    invoice.aasm.events(permitted: true).collect{|x| x.name.to_s}
  end
end
