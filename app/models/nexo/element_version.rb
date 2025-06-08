# == Schema Information
#
# Table name: nexo_element_versions
#
#  id         :bigint           not null, primary key
#  element_id :bigint           not null
#  payload    :string
#  etag       :string
#  sequence   :integer
#  origin     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  nev_status :integer          not null
#
module Nexo
  # sequence
  #
  #   cuando es null significa que el origin es external que debe ser
  #   sincronizado. si está presente, significa que fue sincronizado
  #   incremental correlativa. puede ser discontinua si se generan updates
  #   a una frecuencia alta
  #   TODO!: rename to "version"
  #
  # etag
  #
  #   id de versión remota, para evitar pisar datos remotos aún no fetcheados y
  #   para no volver a traer datos si no hubo ningún cambio desde la última vez
  #   que se fetchearon
  #
  # payload
  #
  #   raw data from API
  class ElementVersion < ApplicationRecord
    belongs_to :element, class_name: "Nexo::Element"

    enum :origin, internal: 0, external: 1
    enum :nev_status, pending_sync: 0, synced: 1, ignored_in_conflict: 2, superseded: 3

    serialize :payload, coder: JSON

    validates :origin, presence: true
  end
end
