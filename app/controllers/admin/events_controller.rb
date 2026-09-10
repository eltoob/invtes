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

    private

    def set_event
      @event = Event.find_by!(slug: params[:id])
    end
  end
end
