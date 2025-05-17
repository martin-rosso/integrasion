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
    describe "build_remote_service", pending: "moved to ServiceBuilder" do
      it do
        element = nexo_elements(:initialized)
        expect(element.build_remote_service).to be_a GoogleCalendarService
      end
    end
  end
end
