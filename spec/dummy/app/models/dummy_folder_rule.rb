class DummyFolderRule < ApplicationRecord
  belongs_to :folder, class_name: "Nexo::Folder"

  enum :sync_policy, { include: 0, exclude: 1 }

  def applies?(synchronizable)
    synchronizable.summary.match?(/#{search_regex}/).tap do |result|
      Nexo.logger.tagged("DummyFolderRule").debug { "Matching result: #{result}" }
    end
  end

  def synchronizable_queries
    [ Event.all ]
  end
end
