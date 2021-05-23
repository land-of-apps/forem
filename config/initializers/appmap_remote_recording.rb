if ENV["APPMAP"] == "true" && %w[test development].member?(Rails.env)
  require "appmap/middleware/remote_recording"

  Rails.application.config.middleware.insert_after \
    Rails::Rack::Logger,
    AppMap::Middleware::RemoteRecording
end
