class RsvpMailer < ApplicationMailer
  # Comma-separated list of hosts to notify on every RSVP.
  def self.recipients = ENV.fetch("RSVP_NOTIFY_EMAILS", "").split(",").map(&:strip).compact_blank
  def self.enabled? = recipients.any?

  def notify(rsvp, updated: false)
    @rsvp = rsvp
    @event = rsvp.event
    @updated = updated
    answer = rsvp.attending? ? "Yes#{" (+#{rsvp.guests_count})" if rsvp.guests_count.positive?}" : "No"
    prefix = updated ? "RSVP updated" : "New RSVP"
    mail to: self.class.recipients,
         subject: "#{prefix} for #{@event.name}: #{rsvp.name} – #{answer}"
  end
end
