require "googleauth/token_store"

module Nexo
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
    def store(integration, token)
      ActiveRecord::Base.transaction do
        # Maybe these should be destroyed
        integration.tokens.active.update_all(tpt_status: :expired)

        Token.create!(integration:, secret: token)
      end
    end

    # (see Google::Auth::Stores::TokenStore#delete)
    def delete(id)
      token = find_by_id(id)

      if token.present?
        token.update!(tpt_status: :revoked)
      else
        # FIXME: pg_warn("Couldn't find token for revocation: #{id}")
      end
    end

    private

    def find_by_id(id)
      Token.where(environment: Rails.env, integration: id, tpt_status: :active).last
    end
  end
end
