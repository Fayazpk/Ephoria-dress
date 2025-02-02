class RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated
  before_action :find_user, only: [:verify_otp, :resend_otp]
  protect_from_forgery with: :exception
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    Rails.logger.debug { "User initialized: #{@user.inspect}" }

    if @user.save
      @user.generate_otp
      UserMailer.send_otp(@user).deliver_now
      redirect_to verify_otp_registration_path(@user.id), notice: "Please check your email for the OTP."
    else
      Rails.logger.debug { "Errors: #{@user.errors.full_messages}" }
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :new
    end
  end

  def verify_otp
    if request.post?
      handle_otp_submission
    else
      # Render the OTP form
    end
  end

  def resend_otp
    if @user
      @user.generate_otp
      UserMailer.send_otp(@user).deliver_now
      flash[:notice] = "New OTP has been sent to your email."
    else
      flash[:alert] = "User not found."
    end
    redirect_to verify_otp_registration_path(@user.id)
  end

  private

  def handle_otp_submission
    submitted_otp = params[:user][:otp]

    if submitted_otp.blank?
      flash[:alert] = "OTP cannot be blank."
      render :verify_otp and return
    end

    if @user.otp_code == submitted_otp && @user.otp_expires_at > Time.current
      @user.update(verified: true)
      flash[:notice] = "OTP verified successfully!"
      redirect_to usermodule_home_index_path
    else
      flash[:alert] = "Invalid or expired OTP."
      render :verify_otp
    end
  end

  def find_user
    @user = User.find_by(id: params[:id])
    unless @user
      flash[:alert] = "User not found"
      redirect_to new_registration_path
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def redirect_if_authenticated
    redirect_to usermodule_home_index_path, notice: "You are already logged in." if user_signed_in? && !request.path.include?("/auth/")
  end
end
