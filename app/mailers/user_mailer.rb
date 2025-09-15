class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = verify_email_url(token: @user.generate_token_for(:email_verification))
    
    mail(
      to: @user.email,
      subject: "Verify your email address - Clay Community"
    )
  end
end
