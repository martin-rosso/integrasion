class DummyFolderRule
  include Nexo::FolderRule

  def initialize(search, sync_policy, priority)
    @search = search
    @sync_policy = sync_policy
    @priority = priority
  end

  def match?(synchronizable)
    synchronizable.summary.match?(@search)
  end
end
