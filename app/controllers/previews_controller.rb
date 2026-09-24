# Serves the link-preview card (og:image) for an event's invite page.
class PreviewsController < ApplicationController
  def show
    event = Event.find_by!(slug: params[:slug])
    preview = EventPreviewImage.new(event)
    expires_in 1.day, public: true
    send_data Rails.cache.fetch(preview.cache_key) { preview.to_jpeg },
      type: "image/jpeg", disposition: "inline"
  end
end
