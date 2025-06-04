# :nocov: TODO
module Nexo
  class ElementVersionsController < ApplicationController
    def show
      @element_version = ElementVersion.find(params[:id])
    end

    def sync
      @element_version = ElementVersion.find(params[:id])

      case params[:operation]
      when "import"
        ImportRemoteElementVersion.new.perform(@element_version)
        notice = "Imported"
      when "update_remote"
        UpdateRemoteResourceJob.perform_later(@element_version)
        notice = "enqueued UpdateRemoteResourceJob"
      else
        raise "unkown action"
      end

      redirect_to @element_version, notice:
    rescue StandardError => e
      redirect_to @element_version, alert: e.message
    end
  end
end
# :nocov:
