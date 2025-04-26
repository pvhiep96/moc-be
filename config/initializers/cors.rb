Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any,
                  expose:  %w[X-Total X-Total-Pages X-Page X-Per-Page X-Next-Page X-Prev-Page X-Offset],
                  methods: %i[get post patch put delete]
  end
end
