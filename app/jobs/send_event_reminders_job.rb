# Runs on a schedule (config/recurring.yml). Finds events whose reminder
# time has passed and enqueues one reminder SMS per attending guest.
class SendEventRemindersJob < ApplicationJob
  queue_as :default

  def perform(event = nil)
    events = event ? [ event ] : Event.due_for_reminder.to_a

    events.each do |ev|
      ev.rsvps.needing_reminder.find_each do |rsvp|
        SendReminderSmsJob.perform_later(rsvp)
      end
      ev.update_column(:reminder_sent_at, Time.current)
    end
  end
end
