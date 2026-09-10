module Admin
  class BaseController < ApplicationController
    layout "admin"

    http_basic_authenticate_with name: ENV.fetch("ADMIN_USERNAME", "admin"),
                                 password: ENV.fetch("ADMIN_PASSWORD") {
                                   Rails.env.production? ? SecureRandom.hex(32) : "password"
                                 }
  end
end
