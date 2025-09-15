require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "email_verification" do
    let(:user) { create(:user) }
    let(:mail) { UserMailer.email_verification(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Verify your email address - Clay Community")
      expect(mail.to).to eq(["user1@example.com"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
