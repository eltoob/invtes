module Admin
  class EventsController < BaseController
    before_action :set_event, except: :index

    def index
      @events = Event.order(starts_at: :desc)
    end

    def show
      @rsvps = @event.rsvps.order(created_at: :desc)
      @attending = @rsvps.attending
      @declined = @rsvps.declined
    end

    def export
      csv = CSV.generate do |out|
        out << [ "Name", "Phone", "Attending", "Guests", "Party size", "Note", "RSVP'd at", "Confirmation sent", "Reminder sent" ]
        @event.rsvps.order(:name).each do |r|
          out << [ r.name, r.phone, r.attending? ? "Yes" : "No", r.guests_count, r.party_size, r.note,
                   r.created_at.in_time_zone(@event.tz), r.confirmation_sent_at, r.reminder_sent_at ]
        end
      end
      send_data csv, filename: "#{@event.slug}-rsvps-#{Date.current}.csv", type: "text/csv"
    end

    # Manual "send reminders now" button, e.g. for testing or a late change.
    def send_reminders
      count = @event.rsvps.needing_reminder.count
      SendEventRemindersJob.perform_later(@event)
      redirect_to admin_event_path(@event), notice: "Queued reminder texts for #{count} #{'guest'.pluralize(count)}."
    end

    def edit
    end

    def update
      if @event.update(event_attributes)
        redirect_to admin_event_path(@event), notice: "Event updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    LOCAL_TIME_FIELDS = %i[starts_at ends_at reminder_at].freeze
    private_constant :LOCAL_TIME_FIELDS

    private

    # Times are entered on the form as local wall-clock times in the event's
    # time zone (datetime-local inputs carry no zone), so parse them in the zone
    # being saved. A blank reminder time falls back to the model default.
    def event_attributes
      attrs = params.require(:event).permit(:name, :timezone, :location, :details, :reminder_message,
                                            :reset_reminder, *LOCAL_TIME_FIELDS).to_h.symbolize_keys
      zone = ActiveSupport::TimeZone[attrs[:timezone].to_s] || @event.tz
      LOCAL_TIME_FIELDS.each do |field|
        next unless attrs.key?(field)
        attrs[field] = attrs[field].present? ? zone.parse(attrs[field]) : nil
      end
      attrs[:reminder_sent_at] = nil if attrs.delete(:reset_reminder) == "1"
      attrs
    end

    def set_event
      @event = Event.find_by!(slug: params[:id])
    end
  end
end
