# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 2.minute, roles: [:app, :staging] do
  runner "Amura::SidekiqManager.run"
end

every 4.hour, roles: [:app, :staging] do
  runner "Amura::SidekiqManager.restart"
end

every 3.minutes do
  runner "Gamification::Job.new.execute"
end

every 1.day, at: "4:30 am" do
  runner "ProjectUnitRemindersAndAutoRelease::Job.daily_reminder_for_booking_payment"
  runner "ReceiptCleaner.perform_async"
  runner "ReminderWorker.perform_async"
  # runner "ProjectUnitRemindersAndAutoRelease::Job.release_project_unit"
end

# every 1.minute do
#   runner "UpgradePricing.perform"
# end

every 1.day, at: "3:30 pm" do
  runner "DailySmsReportWorker.perform_async"
  runner 'ReceiptCleaner.perform_async'
end

every 1.day, at: "3:00 pm" do
  runner "DailyReports::PaymentsReportWorker.perform_async"
end
