class AuthController < ApplicationController
  def index
    # If not go ahead and get one
    client_secrets = Google::APIClient::ClientSecrets.load 'config/google_api_client_secret.json'
    auth_client = client_secrets.to_authorization
    auth_client.update!(
        :scope => Google::Apis::DriveV3::AUTH_DRIVE,
        :redirect_uri => auth_index_url,
        # TODO: remove this hardcode refresh token and save it the DB instead
        :refresh_token => '1/DF4DPODLH7GayP4EmEDG1fUi3-FKjYyd0DJgUhiRSPc'
    )
    
    if request[:code].nil?
      post_auth_redirect_uri = params[:redirect] || root_path
      session[:post_auth_redirect_uri] = post_auth_redirect_uri
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri
    else
      auth_client.code = request['code']
      auth_client.fetch_access_token!
      session[:google_drive_credential] = auth_client.to_json
      redirect_to session[:post_auth_redirect_uri] || root_path
    end
  end
end
