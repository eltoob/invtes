class SendRsvpConfirmationJob < ApplicationJob
  queue_as :default
  retry_on SmsSender::Error, wait: :polynomially_longer, attempts: 5

  def perform(rsvp)
    event = rsvp.event
    body =
      if rsvp.attending?
        party = rsvp.guests_count.positive? ? " (+#{rsvp.guests_count})" : ""
        "Thanks #{rsvp.first_name}! You're on the list for #{event.name}#{party} on " \
        "#{event.local_starts_at.strftime('%a %b %-d at %-l:%M %p')}. We'll text you a reminder the day before."
      else
        "Thanks #{rsvp.first_name}, we've noted you can't make #{event.name}. We'll miss you!"
      end

    SmsSender.call(to: rsvp.phone, body: body)
    rsvp.update_column(:confirmation_sent_at, Time.current)
  end
end
