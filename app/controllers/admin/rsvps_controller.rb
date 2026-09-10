module Admin
  class RsvpsController < BaseController
    def destroy
      event = Event.find_by!(slug: params[:event_id])
      event.rsvps.find(params[:id]).destroy
      redirect_to admin_event_path(event), notice: "RSVP removed."
    end
  end
end
