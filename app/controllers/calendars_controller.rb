# Serves the "Add to my calendar" file for an event.
class CalendarsController < ApplicationController
  def show
    event = Event.find_by!(slug: params[:slug])
    calendar = EventCalendar.new(event, url: invitation_url(event.slug))
    send_data calendar.to_ics,
      type: "text/calendar; charset=utf-8",
      disposition: "attachment",
      filename: calendar.filename
  end
end
