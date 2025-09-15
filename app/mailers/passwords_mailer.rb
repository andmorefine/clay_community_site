class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail(
      to: user.email,
      subject: "Reset your password - Clay Community"
    )
  end
end
