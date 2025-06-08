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
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ne_status           :integer          not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Element, type: :model do
    let(:element) { create(:nexo_element) }

    it "conflicted trait works" do
      element = create(:nexo_element, :conflicted)
      expect(element).to be_conflicted
      element.update_ne_status!
      expect(element).to be_conflicted
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
