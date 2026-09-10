# Sends an SMS through Twilio. When Twilio credentials are missing
# (e.g. local development), the message is logged instead of sent.
class SmsSender
  class Error < StandardError; end

  def self.call(to:, body:) = new.call(to: to, body: body)

  def call(to:, body:)
    if configured?
      client.messages.create(from: from_number, to: to, body: body)
      Rails.logger.info("[SmsSender] sent to #{to}")
    else
      Rails.logger.info("[SmsSender] (not configured, logging only) to=#{to} body=#{body.inspect}")
    end
    true
  rescue Twilio::REST::TwilioError => e
    raise Error, e.message
  end

  def configured?
    account_sid.present? && auth_token.present? && from_number.present?
  end

  private

  def account_sid = ENV["TWILIO_ACCOUNT_SID"]
  def auth_token  = ENV["TWILIO_AUTH_TOKEN"]
  def from_number = ENV["TWILIO_FROM_NUMBER"]

  def client
    @client ||= Twilio::REST::Client.new(account_sid, auth_token)
  end
end
