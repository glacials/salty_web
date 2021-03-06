class TwitchController < ApplicationController

  def to_twitch
    redirect_to "https://api.twitch.tv/kraken/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=user_read"
  end

  def from_twitch
    oauth = HTTParty.post("https://api.twitch.tv/kraken/oauth2/token", query: full_twitch_info)['access_token']
    user_data = HTTParty.get("https://api.twitch.tv/kraken/user?oauth_token=#{oauth}")

    user = User.find_by twitch_id: user_data['_id']

    if user.nil?
      user = User.new(email: user_data['email'], twitch_id: user_data['_id'], twitch_name: user_data['name'])
      user.create_settings!
    end

    user.oauth = oauth
    user.session = User.digest((SecureRandom.urlsafe_base64).to_s)

    if user.save
      sign_in user
      redirect_to salty_path
    end
  end

  def sign_out
    destroy
    flash[:success] = "Signed out"
    redirect_to root_path
  end

  private
    def client_id
      client_id = ENV["salty_client_id"]
    end

    def client_secret
      client_secret = ENV["salty_client_secret"]
    end

    def redirect_uri
      if !Rails.env.development?
        redirect_uri = "https://#{request.host_with_port}/twitch/salty/auth"
      else
        redirect_uri = "http://#{request.host_with_port}/twitch/salty/auth"
      end
    end

    def full_twitch_info
      {client_id:     client_id,
       client_secret: client_secret,
       grant_type:    'authorization_code',
       redirect_uri:  redirect_uri,
       code:          params[:code]}
    end
end
