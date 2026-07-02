# frozen_string_literal: true

Yookassa::Engine.routes.draw do
  post "/webhooks/:token", to: "webhooks#create"
end
