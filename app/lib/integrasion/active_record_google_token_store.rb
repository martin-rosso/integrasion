require "googleauth/token_store"

module Integrasion
  class ActiveRecordGoogleTokenStore < Google::Auth::TokenStore
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
    def store(third_party_integration, token)
      ActiveRecord::Base.transaction do
        # Maybe these should be destroyed
        third_party_integration.third_party_tokens.active.update_all(tpt_status: :expired)

        ThirdPartyToken.create!(environment: Rails.env, third_party_integration:, secret: token, tpt_status: :active)
      end
    end

    # (see Google::Auth::Stores::TokenStore#delete)
    def delete(id)
      token = find_by_id(id)

      if token.present?
        token.update!(tpt_status: :revoked)
      else
        pg_warn("Couldn't find token for revocation: #{id}")
      end
    end

    private

    def find_by_id(id)
      ThirdPartyToken.where(environment: Rails.env, third_party_integration: id, tpt_status: :active).last
    end
  end
end
