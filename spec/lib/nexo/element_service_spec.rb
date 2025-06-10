require "rails_helper"

module Nexo
  describe ElementService do
    describe "create_internal_version_if_none!" do
      subject do
        service.create_internal_version_if_none!
      end

      let(:service) { described_class.new(element:) }
      let!(:element) { create(:nexo_element, :synced) }

      it "doesnt create a version" do
        expect { subject }.not_to change(ElementVersion, :count)
      end
    end

    describe "flag_for_removal!" do
      subject do
        service.flag_for_removal!(reason)
        element.reload
      end

      let(:service) { described_class.new(element:) }
      let(:element) { create(:nexo_element, :synced) }
      let(:reason) { :no_longer_included_in_folder }

      it do
        expect { subject }.to change(element, :flagged_for_removal?)
      end
    end

    describe "update_synchronizable!" do
      subject do
        service.update_synchronizable!
      end

      let(:service) { described_class.new(element_version:) }

      let(:event) { create(:event) }
      let(:element) { create(:nexo_element, synchronizable: event) }

      pending "when ActiveRecord::RecordNotUnique"

      context "all-day" do
        let(:element_version) { create(:nexo_element_version, :all_day, :unsynced_external_change, element:) }

        it "when its an all-day event" do
          expect { subject }.to change { element_version.reload.sequence }.to(be_present)
            .and(change { event.reload.summary }.to("test-summary"))
            .and(change { event.reload.date_from }.to(Date.parse("2025-06-05")))
            .and(change { event.reload.date_to }.to(Date.parse("2025-06-06")))
        end
      end

      context "when event has time / i.e.: not an all-day event" do
        let(:element_version) { create(:nexo_element_version, :with_time, :unsynced_external_change, element:) }

        it "when it has time" do
          expect { subject }.to change { element_version.reload.sequence }.to(be_present)
            .and(change { event.reload.summary }.to("test-summary"))
            .and(change { event.reload.date_from }.to(Date.parse("2025-06-11")))
            .and(change { event.reload.date_to }.to(Date.parse("2025-06-11")))
            .and(change { event.reload.time_from }.to(Time.parse("2000-01-01T10:00")))
            .and(change { event.reload.time_to }.to(Time.parse("2000-01-01T14:30")))
        end
      end
    end
  end
end
