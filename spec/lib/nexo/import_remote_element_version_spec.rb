require 'rails_helper'

module Nexo
  describe ImportRemoteElementVersion do
    subject do
      described_class.new.perform(element_version)
      element_version.reload
    end

    let(:element_version) { create :nexo_element_version, :unsynced_external_change }

    it "marks the version as superseded" do
      create :nexo_element_version, :synced, element: element_version.element
      expect { subject }.to change(element_version, :nev_status).to "superseded"
    end
  end
end
