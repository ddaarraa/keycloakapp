Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  provider :keycloak_openid, ENV['KEYCLOAK_CLIENT_ID'], ENV['KEYCLOAK_CLIENT_SECRET'], client_options: {
    site: ENV['KEYCLOAK_SITE'],
    realm: ENV['KEYCLOAK_REALM']
  }
end
