# Serve .m4a audio as audio/mp4 (Rack's default "audio/mp4a-latm" is rejected by Safari/iOS).
Rack::Mime::MIME_TYPES[".m4a"] = "audio/mp4"
