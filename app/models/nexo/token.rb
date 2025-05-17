# == Schema Information
#
# Table name: nexo_tokens
#
#  id             :integer          not null, primary key
#  integration_id :integer          not null
#  secret         :string
#  tpt_status     :integer          not null
#  environment    :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
module Nexo
  class Token < ApplicationRecord
    belongs_to :integration, class_name: "Nexo::Integration"

    after_initialize do
      # TODO: https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute
      self.tpt_status = :active if tpt_status.nil?
      self.environment = Rails.env if environment.nil?
    end

    encrypts :secret

    enum :tpt_status, active: 0, revoked: 1, expired: 2

    validates :secret, :tpt_status, :environment, presence: true
  end
end
