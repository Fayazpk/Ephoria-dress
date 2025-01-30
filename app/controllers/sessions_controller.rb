class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new, :create]

  def new
    Rails.logger.debug "SessionsController#new called"
    redirect_to root_path if user_signed_in?
  end

  def create
    Rails.logger.debug "SessionsController#create called with params: #{params.inspect}"
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      Rails.logger.debug "User authenticated successfully: #{user.inspect}"
      login(user)

      if user.admin?
        Rails.logger.debug "Admin user redirected to admin dashboard"
        redirect_to admin_dashboard_path, notice: "Logged in successfully!"
      else
        Rails.logger.debug "Regular user redirected to usermodule home index"
        redirect_to usermodule_home_index_path, notice: "Logged in successfully!"
      end
    else
      Rails.logger.debug "Invalid email or password provided"
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.debug "SessionsController#destroy called"
    logout
    redirect_to root_path, notice: "Logged out successfully!"
  end

  def oauth_callback
    Rails.logger.debug "SessionsController#oauth_callback called with auth: #{request.env['omniauth.auth'].inspect}"
    auth = request.env['omniauth.auth']
    @user = User.from_omniauth(auth)

    session[:user_id] = @user.id
    Rails.logger.debug "User signed in via OAuth: #{@user.inspect}"
    redirect_to root_path, notice: 'Successfully signed in!'
  end

  def oauth_request
    Rails.logger.info "OAuth request initiated"
    redirect_to '/auth/google_oauth2', allow_other_host: true
  end

  def failure
    Rails.logger.debug "SessionsController#failure called"
    redirect_to root_path, alert: 'Authentication failed.'
  end

  private

  def redirect_if_authenticated
    Rails.logger.debug "SessionsController#redirect_if_authenticated called"
    redirect_to usermodule_home_index_path, notice: "You are already logged in." if user_signed_in?
  end
end
