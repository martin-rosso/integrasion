# == Schema Information
#
# Table name: nexo_elements
#
#  id                  :integer          not null, primary key
#  folder_id           :integer          not null
#  synchronizable_id   :integer          not null
#  synchronizable_type :string           not null
#  uuid                :string
#  flag_deletion       :boolean          not null
#  deletion_reason     :integer
#  conflicted          :boolean          default(FALSE), not null
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Element, type: :model do
    describe "flag_for_deletion!" do
      subject do
        element.flag_for_deletion!(reason)
      end

      let(:element) { nexo_elements(:synced) }
      let(:reason) { :no_longer_included_in_folder }

      it do
        expect { subject }.to change(element, :flagged_for_deletion?)
      end
    end
  end
end
