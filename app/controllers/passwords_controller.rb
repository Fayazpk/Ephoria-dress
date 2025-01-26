class PasswordsController < ApplicationController
    def create
      user = User.find_by(email: params[:email])
      
      if user
        user.generate_password_reset_token!
        PasswordResetMailer.reset_email(user).deliver_now
        
        redirect_to root_path, notice: 'Password reset instructions sent to your email.'
      else
        flash.now[:alert] = 'Email not found in our system.'
        render :new, status: :unprocessable_entity
      end
    end
  
    def update
      @user = User.find_by(reset_token: params[:token])
      
      if @user && @user.reset_token_expires_at > Time.current
        if params[:password] == params[:password_confirmation]
          if @user.reset_password(params[:password])
            redirect_to new_session_path, notice: 'Password successfully reset.'
          else
            flash.now[:alert] = 'Password reset failed.'
            render :edit
          end
        else
          flash.now[:alert] = 'Passwords do not match.'
          render :edit
        end
      else
        redirect_to new_session_path, alert: 'Invalid or expired reset token.'
      end
    end
  end