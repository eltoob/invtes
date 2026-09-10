class Event < ApplicationRecord
  has_many :rsvps, dependent: :destroy

  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase letters, numbers and dashes" }
  validates :name, :starts_at, :timezone, presence: true
  validate :timezone_must_exist
  validate :ends_at_after_starts_at

  before_validation :default_reminder_at

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :due_for_reminder, -> {
    where(reminder_sent_at: nil)
      .where("reminder_at <= ?", Time.current)
      .where("starts_at > ?", Time.current)
  }

  def to_param = slug

  def tz = ActiveSupport::TimeZone[timezone]
  def local_starts_at = starts_at.in_time_zone(tz)
  def local_ends_at = ends_at&.in_time_zone(tz)

  # Attendees who said yes, plus the guests they're bringing.
  def attending_rsvps = rsvps.where(attending: true)
  def headcount = attending_rsvps.sum("1 + guests_count")

  # Lookup of the ERB partial that renders this event's custom page.
  # Falls back to the default design if no partial exists for the slug.
  def template_partial
    custom = "invitations/templates/#{slug.tr('-', '_')}"
    ApplicationController.new.lookup_context.exists?(custom, [], true) ? custom : "invitations/templates/default"
  end

  def reminder_text_for(rsvp)
    template = reminder_message.presence ||
      "Hi %{name}! Reminder: %{event} is tomorrow, %{when}%{where}. See you there!"
    format(template,
      name: rsvp.first_name,
      event: name,
      when: local_starts_at.strftime("%-l:%M %p"),
      where: location.present? ? " at #{location}" : "",
      date: local_starts_at.strftime("%A, %B %-d"),
      guests: rsvp.guests_count)
  end

  private

  def ends_at_after_starts_at
    errors.add(:ends_at, "must be after the start time") if ends_at.present? && starts_at.present? && ends_at <= starts_at
  end

  def timezone_must_exist
    errors.add(:timezone, "is not a known time zone") if timezone.present? && tz.nil?
  end

  # Default: 10:00 AM local time the day before the event.
  def default_reminder_at
    return if reminder_at.present? || starts_at.blank? || tz.nil?
    self.reminder_at = (local_starts_at - 1.day).change(hour: 10, min: 0)
  end
end
