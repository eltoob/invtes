class SendReminderSmsJob < ApplicationJob
  queue_as :default
  retry_on SmsSender::Error, wait: :polynomially_longer, attempts: 5

  def perform(rsvp)
    return if rsvp.reminder_sent_at.present? || !rsvp.attending?

    SmsSender.call(to: rsvp.phone, body: rsvp.event.reminder_text_for(rsvp))
    rsvp.update_column(:reminder_sent_at, Time.current)
  end
end
