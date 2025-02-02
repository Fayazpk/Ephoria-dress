class PasswordResetMailer < ApplicationMailer
  def reset_email(user)
    @user = user
    @reset_url = password_reset_url(token: user.reset_token)

    mail(
      to: user.email,
      subject: 'Password Reset Instructions',
      from: 'noreply@euphoria.com'
    )
  end
end