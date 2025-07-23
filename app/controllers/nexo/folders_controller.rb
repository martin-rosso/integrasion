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
      @policies = PolicyService.instance.policies_for(@folder)
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
      when "perform_sync"
        @folder.elements.kept.each do |element|
          ElementService.new(element:)._perform_sync!
        end
        redirect_to @folder, notice: "Executed _perform_sync!"
      when "folder_sync_job"
        FolderSyncJob.perform_later(@folder)
        redirect_to @folder, notice: "Enqueued FolderSyncJob"
      when "discard_folder"
        @folder.discard!
        EventReceiver.new.folder_discarded(@folder)
      when "watch"
        GoogleCalendarService.new(@folder.integration).watch_calendar(@folder)

        redirect_to @folder, notice: "Watching folder"
      else
        redirect_to @folder, alert: "Unknown action"
      end
    end
  end
end
