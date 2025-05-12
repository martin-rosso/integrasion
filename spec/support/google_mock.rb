def mock_get_credentials
  mock = instance_double(Google::Auth::UserRefreshCredentials, expires_at: 10.minutes.from_now)
  allow_any_instance_of(Google::Auth::WebUserAuthorizer).to receive(:get_credentials).and_return(mock)
end
