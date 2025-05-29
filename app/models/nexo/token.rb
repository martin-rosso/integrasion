# == Schema Information
#
# Table name: nexo_tokens
#
#  id             :bigint           not null, primary key
#  integration_id :bigint           not null
#  secret         :string
#  nt_status      :integer          not null
#  environment    :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
module Nexo
  class Token < ApplicationRecord
    belongs_to :integration, class_name: "Nexo::Integration"

    scope :active, -> { where(nt_status: :active) }

    after_initialize do
      # TODO: https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute
      self.nt_status = :active if nt_status.nil?
      self.environment = Rails.env if environment.nil?
    end

    encrypts :secret

    enum :nt_status, active: 0, revoked: 1, expired: 2

    validates :secret, :nt_status, :environment, presence: true
  end
end
