require 'rails_helper'

module Integrasion
  describe "integrations requests", type: :request do
    let(:client) { Client.first }

    let(:integration) do
      Integration.create!(user: User.first, client: client, scope: [ "auth_calendar_app_created" ])
    end

    before do
      host! 'localhost:3000'
    end

    describe "new" do
      it do
        get "/integrations/new", params: { client_id: client.id }

        expect(response).to be_successful
      end

      pending "without client_id" do
        get "/integrations/new"

        expect(response).to be_successful
      end
    end

    describe "show" do
      it do
        get "/integrations/#{integration.id}"

        expect(response).to be_successful
      end
    end

    describe "authorization flow" do
      it do
        get "/integrations/#{integration.id}"
        result = body.match /href=\"(.*oauth2.*)\"/
        url = result[1]

        # puts url.gsub('&amp\;', '&')
        expect(url).to match /localhost:3000/

        new_url = "/u/google/callback?state=%7B%22session_id%22:%22ebU1fag%3D%3D%22,%22current_uri%22:%22http://localhost:3000/integrations/1%22%7D&code=4/0Ab_&scope=https://www.googleapis.com/auth/calendar.calendarlist%20https://www.googleapis.com/auth/calendar.app.created"

        mock = double(Google::Auth::UserRefreshCredentials.new, expires_at: 10.minutes.from_now)
        allow_any_instance_of(Google::Auth::WebUserAuthorizer).to receive(:get_credentials).and_return(mock)

        get new_url

        follow_redirect!

        expect(response.body).to match /active_token/
      end
    end
  end
end
