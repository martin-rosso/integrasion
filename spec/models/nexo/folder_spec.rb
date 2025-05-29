# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :bigint           not null, primary key
#  integration_id      :bigint           not null
#  nexo_protocol       :integer          not null
#  external_identifier :string
#  name                :string
#  description         :string
#  discarded_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

module Nexo
  RSpec.describe Folder, type: :model do
    let(:folder) { create(:nexo_folder) }

    it "factory works" do
      expect { folder }.to change(Nexo::Folder, :count).by(1)
    end

    describe "find_element" do
      subject do
        folder.find_element(synchronizable: event)
      end

      let(:event) { create(:event) }

      context "when more thant one element" do
        before do
          create_list(:nexo_element, 2, folder:, synchronizable: event)
        end

        it do
          expect { subject }.to raise_error(Errors::MoreThanOneElementInFolderForSynchronizable)
        end
      end

      context "when there is a discarded element" do
        let(:event) { create(:event) }

        before do
          create(:nexo_element, :discarded, folder:, synchronizable: event)
          create(:nexo_element, folder:, synchronizable: event)
        end

        it "returns an element" do
          expect(subject).to be_a Element
        end
      end
    end

    describe "discard!" do
      it "discards" do
        expect { folder.discard! }.to change(folder, :discarded_at).to be_present
      end
    end
  end
end
