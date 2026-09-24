class ApplicationController < ActionController::Base
  # Crawlers that fetch a shared link to build its preview. iMessage's claims to
  # be Safari 9, so without this exception it gets the "unsupported browser" page.
  LINK_PREVIEW_CRAWLERS = /facebookexternalhit|Facebot|Twitterbot|WhatsApp|Slackbot|TelegramBot|Discordbot|LinkedInBot|Applebot|Googlebot/i

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern, unless: :link_preview_crawler?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def link_preview_crawler? = request.user_agent.to_s.match?(LINK_PREVIEW_CRAWLERS)
end
