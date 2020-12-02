module InvoicesHelper
  def available_events record
    events = record.aasm.events(permitted: true).collect{|x| x.name.to_s}
    if current_user.role?('cp_admin')
      events.select! {|x| x == 'rejected'}
    end
    events
  end
end
