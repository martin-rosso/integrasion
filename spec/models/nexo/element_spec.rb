# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :bigint           not null, primary key
#  folder_id           :bigint           not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  uuid                :string
#  flagged_for_removal :boolean          not null
#  removal_reason      :integer
#  conflicted          :boolean          default(FALSE), not null
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Element, type: :model do
    let(:element) { create(:nexo_element) }

    it "factory works" do
      expect {
        create(:nexo_element, :with_versions)
      }.to change(Nexo::ElementVersion, :count).by(1)
           .and(change(Nexo::Element, :count).by(1))
    end

    describe "flag_for_removal!" do
      subject do
        element.flag_for_removal!(reason)
      end

      let(:element) { create(:nexo_element, :synced) }
      let(:reason) { :no_longer_included_in_folder }

      it do
        expect { subject }.to change(element, :flagged_for_removal?)
      end
    end
  end
end
