module Integrasion
  class ThirdPartyIntegration < ApplicationRecord
    belongs_to :user
    belongs_to :integrasion_third_party_client, class_name: 'Integrasion::ThirdPartyClient'
  end
end
