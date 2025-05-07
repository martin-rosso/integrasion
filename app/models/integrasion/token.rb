# == Schema Information
#
# Table name: integrasion_tokens
#
#  id             :integer          not null, primary key
#  integration_id :integer          not null
#  secret         :json
#  tpt_status     :integer          not null
#  environment    :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
module Integrasion
  class Token < ApplicationRecord
    belongs_to :integration, class_name: "Integrasion::Integration"

    encrypts :secret

    enum :tpt_status, active: 0, revoked: 1, expired: 2

    validates :secret, :tpt_status, :environment, presence: true
  end
end
