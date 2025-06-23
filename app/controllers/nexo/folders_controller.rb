# :nocov: TODO
module Nexo
  class FoldersController < ApplicationController
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

    def full_sync
      FolderDownloadJob.perform_later(@folder, "full_sync")

      redirect_to @folder, notice: "Enqueued full sync"
    end

    def incremental_sync
      FolderDownloadJob.perform_later(@folder, "incremental_sync")

      redirect_to @folder, notice: "Enqueued incremental sync"
    end
  end
end
