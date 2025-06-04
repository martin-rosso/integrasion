# :nocov: TODO
module Nexo
  class ElementsController < ApplicationController
    before_action except: :index do
      @element = Element.find(params[:id])
    end

    def index
      page = params[:page].to_i || 0
      page_size = 100
      @elements = Element.includes(:synchronizable).offset(page * page_size).limit(page_size).order(id: :desc)
    end

    def show
    end

    def update_status
      @element.update_ne_status!

      redirect_to @element, notice: "Updated status"
    end

    def modify_local
      unless Rails.env.local?
        redirect_to @element, alert: "Available only on local env"
        return
      end

      event = @element.synchronizable
      event.date_from = event.date_from + 1.day
      event.date_to = event.date_to + 1.day
      event.save!

      EventReceiver.new.synchronizable_updated(event)

      redirect_to @element, notice: "Modified"
    rescue StandardError => e
      redirect_to @element, alert: e.message
    end

    def fetch_remote
      FetchRemoteResourceJob.perform_later(@element)

      redirect_to @element, notice: "Enqueued FetchRemoteResourceJob"
    end

    def resolve_conflict
      @element.resolve_conflict!

      redirect_to @element, notice: "Conflict solved"
    rescue StandardError => e
      redirect_to @element, alert: e.message
    end
  end
end
# :nocov:
