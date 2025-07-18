# :nocov: TODO
module Nexo
  class ElementsController < NexoController
    before_action except: :index do
      @element = Element.find(params[:id])
    end

    def index
      @elements =
        Element.includes(:synchronizable).order(id: :desc)
               .page(params[:page]).per(params[:page_size] || 10)

      if params[:not_synced]
        @elements = @elements.where.not(ne_status: :synced)
      end
      if params[:without_synchronizable]
        @elements = @elements.where(synchronizable_id: nil)
      end
      I18n.locale = :en
    end

    def show
    end

    def update_status
      ElementService.new(element: @element).update_ne_status!

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
      ElementService.new(element: @element).resolve_conflict!

      redirect_to @element, notice: "Conflict solved"
    rescue StandardError => e
      redirect_to @element, alert: e.message
    end
  end
end
# :nocov:
