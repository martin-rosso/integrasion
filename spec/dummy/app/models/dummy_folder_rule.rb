# Contract / Interface
#
# methods:
#   priority
#     returns an integer
#   sync_policy
#     returns one of ("include", "exclude")
#
#   applies?
#   synchronizable_queries
#   import_payload?
#   create_synchronizable_from_payload!
class DummyFolderRule < ApplicationRecord
  belongs_to :folder, class_name: "Nexo::Folder"

  enum :sync_policy, { include: 0, exclude: 1 }, default: :include

  def applies?(synchronizable)
    synchronizable.summary.match?(/#{search_regex}/).tap do |result|
      Nexo.logger.debug { "Matching result: #{result}" }
    end
  end

  def synchronizable_queries
    [ Event.all ]
  end

  # FIXME: definir la interfaz y comportamiento esperado para este método
  def import_payload?(payload)
    true
  end

  # FIXME: definir la interfaz y comportamiento esperado para este método
  def create_synchronizable_from_payload!(payload)
    Event.create_from_payload!(folder, payload)
  end
end
