require "googleauth/token_store"

module Integrasion
  class ActiveRecordGoogleTokenStore < Google::Auth::TokenStore
    def initialize(third_party_integration)
      @third_party_integration = third_party_integration

      super()
    end

    # (see Google::Auth::Stores::TokenStore#load)
    def load(id)
      token = find_by_id(id)

      if token.present?
        token.secret
      else
        nil
      end
    end

    # (see Google::Auth::Stores::TokenStore#store)
    def store(id, token)
      ThirdPartyToken.create!(id_user: id, third_party_integration: @third_party_integration, secret: token)
    end

    # (see Google::Auth::Stores::TokenStore#delete)
    def delete(id)
      token = find_by_id(id)

      if token.present?
        token.destroy!
      else
        pg_warn("Couldn't find token for deletion: #{id}")
      end
    end

    private

    def find_by_id(id)
      ThirdPartyToken.where(id_user: id, third_party_integration: @third_party_integration).first
    end
  end
end
