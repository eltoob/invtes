class RsvpsController < ApplicationController
  def create
    event = Event.find_by!(slug: params[:slug])
    attrs = rsvp_params

    # Same phone RSVPing again for the same event updates their answer.
    phone = Phonelib.parse(attrs[:phone]).e164 || attrs[:phone]
    rsvp = event.rsvps.find_or_initialize_by(phone: phone)
    rsvp.assign_attributes(attrs)
    rsvp.guests_count = 0 unless rsvp.attending?

    answer_changed = rsvp.new_record? || rsvp.attending_changed? || rsvp.guests_count_changed?
    if rsvp.save
      # Text a confirmation on first RSVP, and again if they change their answer (only when Twilio is set up).
      SendRsvpConfirmationJob.perform_later(rsvp) if answer_changed && SmsSender.new.configured?
      render json: {
        ok: true,
        attending: rsvp.attending?,
        name: rsvp.first_name,
        guests_count: rsvp.guests_count,
        message: confirmation_message(rsvp)
      }
    else
      render json: { ok: false, errors: rsvp.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def confirmation_message(rsvp)
    return "Sorry you can't make it. We've noted it." unless rsvp.attending?
    "You're in! We've saved your spot."
  end

  def rsvp_params
    p = params.require(:rsvp).permit(:name, :phone, :attending, :guests_count, :note)
    p[:attending] = ActiveModel::Type::Boolean.new.cast(p[:attending])
    p[:attending] = true if p[:attending].nil?
    p
  end
end
