require "rails_helper"

module Nexo
  describe PolicyService do
    subject do
      described_class.instance
    end

    # before do
    #   Nexo.folder_policies.register_folder_policy_finder do |folder|
    #     if folder.name.include?("Other")
    #       DummyFolderPolicy.new("with_nil_sequence", :always, 1)
    #     else
    #       DummyFolderPolicy.new("initialized", :always, 1)
    #     end
    #   end
    # end

    # it do
    #   event = create(:event)
    #   folder = create(:nexo_folder)
    #   expect(subject.applies?(folder, event)).to be_truthy
    # end

    # it do
    #   event = create(:event)
    #   folder = create(:nexo_folder)
    #   expect(subject.applies?(folder, event)).to be_falsey
    # end

    # it do
    #   event = create(:event)
    #   folder = create(:nexo_folder)
    #   expect(subject.applies?(folder, event)).to be_truthy
    # end
  end
end
