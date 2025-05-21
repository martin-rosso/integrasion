# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :bigint           not null, primary key
#  integration_id      :bigint           not null
#  protocol            :integer          not null
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
    let(:folder) { nexo_folders(:default) }

    describe "find_element" do
      subject do
        folder.find_element(synchronizable: event)
      end

      let(:event) { events(:initialized) }

      it do
        expect { subject }.to raise_error(Errors::MoreThanOneElementInFolderForSynchronizable)
      end

      context "when there is a discarded element" do
        let(:event) { events(:event_with_discarded_element) }

        it "returns an element" do
          expect(subject).to be_a Element
        end
      end
    end
  end
end
