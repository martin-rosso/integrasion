# :nocov: TODO
module Nexo
  class ElementsController < NexoController
    before_action except: :index do
      @element = Element.find(params[:id])
    end

    def index
      @elements =
        Element.includes(:synchronizable, :folder).order(id: :desc)
               .page(params[:page]).per(params[:page_size] || 25)

      if params[:folder_id]
        @elements = @elements.where(folder_id: params[:folder_id])
      end

      if params[:dirty]
        @elements = @elements.where.not(ne_status: [:synced, :discarded])
      end

      if params[:without_synchronizable]
        @elements = @elements.where(synchronizable_id: nil)
      end
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
    end

    def resolve_conflict
      ElementService.new(element: @element).resolve_conflict!

      redirect_to @element, notice: "Conflict solved"
    end

    def perform_operation
      case params[:operation]
      when "delete"
        DeleteRemoteResourceJob.perform_later(@element)
        redirect_to @element, notice: "Enqueued DeleteRemoteResourceJob"
      when "fetch_remote"
        FetchRemoteResourceJob.perform_later(@element)
        redirect_to @element, notice: "Enqueued FetchRemoteResourceJob"
      when "perform_sync"
        ElementService.new(element: @element)._perform_sync!
        redirect_to @element, notice: "Executed _perform_sync!"
      when "discard"
        ElementService.new(element: @element).discard!
        redirect_to @element, notice: "Element discarded"
      when "increment_sequence"
        synchronizable = @element.synchronizable
        synchronizable.increment_sequence!

        EventReceiver.new.synchronizable_updated(synchronizable)

        redirect_to @element, notice: "Incremented sequence to: #{synchronizable.sequence} and called synchronizable_updated"
      else
        redirect_to @element, alert: "Unknown action"
      end
    end
  end
end
# :nocov:
