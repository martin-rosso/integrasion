# == Schema Information
#
# Table name: nexo_folders
#
#  id                  :integer          not null, primary key
#  integration_id      :integer          not null
#  protocol            :integer          not null
#  external_identifier :string
#  name                :string
#  description         :string
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
    end
  end
end
