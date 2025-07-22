# :nocov: TODO
module Nexo
  class FoldersController < NexoController
    before_action except: :index do
      @folder = Folder.find(params[:id])
    end

    def index
      page = params[:page].to_i || 0
      page_size = 100
      @folders = Folder.offset(page * page_size).limit(page_size).order(id: :desc)
    end

    def show
    end

    def check_status
      FolderCheckStatusJob.perform_later(@folder)

      redirect_to @folder, notice: "Checking status"
    end

    def sync
      FolderDownloadJob.perform_later(@folder, "full_or_incremental_sync")

      redirect_to @folder, notice: "Enqueued sync"
    end

    def full_sync
      FolderDownloadJob.perform_later(@folder, "full_sync")

      redirect_to @folder, notice: "Enqueued full sync"
    end

    def incremental_sync
      FolderDownloadJob.perform_later(@folder, "incremental_sync")

      redirect_to @folder, notice: "Enqueued incremental sync"
    end

    def perform_operation
      case params[:operation]
      when "fetch_remote_versions"
        @folder.elements.each do |element|
          FetchRemoteResourceJob.perform_later(element)
        end
        redirect_to @folder, notice: "Enqueued FetchRemoteResourceJob's"
      when "update_ne_statuses"
        @folder.elements.each do |element|
          ElementService.new(element:).update_ne_status!
        end
        redirect_to @folder, notice: "Updated ne_statuses"
      else
        redirect_to @element, alert: "Unknown action"
      end
    end
  end
end
