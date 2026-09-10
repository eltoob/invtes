class Rsvp < ApplicationRecord
  MAX_GUESTS = 10

  belongs_to :event

  validates :name, presence: true, length: { maximum: 120 }
  validates :phone, presence: true, uniqueness: { scope: :event_id, message: "has already RSVP'd for this event" }
  validates :guests_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_GUESTS }
  validate :phone_must_be_valid

  before_validation :normalize_phone

  scope :attending, -> { where(attending: true) }
  scope :declined, -> { where(attending: false) }
  scope :needing_reminder, -> { attending.where(reminder_sent_at: nil) }

  def first_name = name.to_s.split.first.to_s
  def party_size = attending? ? 1 + guests_count : 0

  def formatted_phone
    Phonelib.parse(phone).national
  end

  private

  def normalize_phone
    return if phone.blank?
    parsed = Phonelib.parse(phone)
    self.phone = parsed.e164 if parsed.valid?
  end

  def phone_must_be_valid
    return if phone.blank?
    errors.add(:phone, "doesn't look like a valid mobile number") unless Phonelib.valid?(phone)
  end
end
