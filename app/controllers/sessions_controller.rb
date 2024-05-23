
class SessionsController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  def login
    redirect_to "#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}/protocol/openid-connect/auth?client_id=#{ENV['KEYCLOAK_CLIENT_ID']}&redirect_uri=#{callback_url}&response_type=code&scope=openid"
  end

  def callback
    code = params[:code]
    token_response = get_token(code)

    if token_response
      user_info = get_user_info(token_response["access_token"])
      if user_info
        # Handle user session creation or updating here
        # For example, find or create user in the database
        user = User.find_or_create_by(email: user_info["email"]) do |u|
          u.first_name = user_info["given_name"]
          u.last_name = user_info["family_name"]
          u.username = user_info["preferred_username"]
          u.save()
        end
        session[:user_id] = user.id
        session[:refresh_token] = token_response["refresh_token"]
        redirect_to root_path, notice: 'Signed in successfully'
      else
        redirect_to root_path, alert: 'Failed to get user info'
      end
    else
      redirect_to root_path, alert: 'Failed to obtain access token'
    end
  end

  def destroy
    # session[:user_id] = nil

    # redirect_to root_path
    if Current.user
      keycloak_logout(Current)
      reset_session
      redirect_to root_path, notice: 'Signed out successfully'
    else
      redirect_to root_path, alert: 'No active session'
    end
  end

  private

  def get_token(code)
    uri = URI.parse("#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}/protocol/openid-connect/token")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      'grant_type' => 'authorization_code',
      'client_id' => ENV['KEYCLOAK_CLIENT_ID'],
      'client_secret' => ENV['KEYCLOAK_CLIENT_SECRET'],
      'code' => code,
      'redirect_uri' => callback_url
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    puts "Response Code: #{response.code}"
    puts "Response Message: #{response.message}"
    puts "Response Headers: #{response.each_header.to_h}"
    puts "Response Body: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      nil
    end
  end

  def get_user_info(access_token)
    uri = URI.parse("#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}/protocol/openid-connect/userinfo")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    puts "Response Code: #{response.code}"
    puts "Response Message: #{response.message}"
    puts "Response Headers: #{response.each_header.to_h}"
    puts "Response Body: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      nil
    end
  end

  def keycloak_logout(user)
    uri = URI.parse("#{ENV['KEYCLOAK_SERVER_URL']}/realms/#{ENV['KEYCLOAK_REALM_ID']}/protocol/openid-connect/logout")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      'client_id' => ENV['KEYCLOAK_CLIENT_ID'],
      'client_secret' => ENV['KEYCLOAK_CLIENT_SECRET'],
      'refresh_token' => session[:refresh_token]
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info("User logged out from Keycloak successfully")
    else
      Rails.logger.error("Failed to log out from Keycloak: #{response.body}")
    end
  end

  def callback_url
    url_for(action: 'callback', controller: 'sessions', only_path: false)
  end


end
