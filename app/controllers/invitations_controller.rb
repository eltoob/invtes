class InvitationsController < ApplicationController
  layout "invitation"

  def show
    @event = Event.find_by!(slug: params[:slug])
    @rsvp = @event.rsvps.new
    # Renders app/views/invitations/templates/_<slug>.html.erb, or _default.html.erb
  end
end
