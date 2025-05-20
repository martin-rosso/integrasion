class DummyFolderPolicy
  include Nexo::FolderPolicy

  def initialize(search, sync_policy, priority)
    @search = search
    @sync_policy = sync_policy
    @priority = priority
  end

  def match?(synchronizable)
    synchronizable.summary.match?(@search)
  end

  def synchronizable_queries
    [ Event.all ]
  end

  def folder
    raise "not implemented"
  end
end
