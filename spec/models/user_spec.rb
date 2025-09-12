require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_one_attached(:profile_image) }

    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
    it { is_expected.to have_many(:liked_posts).through(:likes).source(:post) }

    it { is_expected.to have_many(:follows).with_foreign_key('follower_id').dependent(:destroy) }
    it { is_expected.to have_many(:followed_users).through(:follows).source(:followed) }
    it { is_expected.to have_many(:reverse_follows).with_foreign_key('followed_id').class_name('Follow').dependent(:destroy) }
    it { is_expected.to have_many(:followers).through(:reverse_follows).source(:follower) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("foo@bar.com").for(:email) }
    it { is_expected.not_to allow_value("foo").for(:email) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(50) }
    it { is_expected.to allow_value("user_name123").for(:username) }
    it { is_expected.not_to allow_value("foo$bar").for(:username) }

    it {
      is_expected.to validate_inclusion_of(:skill_level).
        in_array(%w[beginner intermediate advanced expert])
    }

    it { is_expected.to validate_length_of(:bio).is_at_most(500) }
  end

  describe "callbacks" do
    it "downcases email before save" do
      user.email = "UPPER@EXAMPLE.COM"
      user.save!
      expect(user.email).to eq("upper@example.com")
    end

    it "downcases username before save" do
      user.username = "UserName"
      user.save!
      expect(user.username).to eq("username")
    end
  end

  describe "scopes" do
    before do
      @u1 = create(:user, skill_level: "beginner", created_at: 1.hour.ago)
      @u2 = create(:user, skill_level: "advanced",  created_at: 2.hours.ago)
      @u3 = create(:user, skill_level: "beginner", created_at: 3.hours.ago)
    end

    it "returns only users with given skill_level" do
      expect(User.by_skill_level("beginner")).to contain_exactly(@u1, @u3)
    end

    it "orders by created_at desc" do
      expect(User.recent.first).to eq(@u1)
    end
  end

  describe "instance methods" do
    let!(:alice) { create(:user) }
    let!(:bob)   { create(:user) }

    describe "#follow" do
      it "creates a follow record" do
        expect { alice.follow(bob) }.to change { Follow.count }.by(1)
        expect(alice.following?(bob)).to be true
      end

      it "does nothing if user tries to follow themselves" do
        expect(alice.follow(alice)).to be_falsey
      end

      it "does not duplicate follows" do
        alice.follow(bob)
        expect { alice.follow(bob) }.not_to change { Follow.count }
      end
    end

    describe "#unfollow" do
      before { alice.follow(bob) }

      it "destroys the follow record" do
        expect { alice.unfollow(bob) }.to change { Follow.count }.by(-1)
        expect(alice.following?(bob)).to be false
      end
    end

    describe "#following?" do
      it "returns true if following, false otherwise" do
        expect(alice.following?(bob)).to be false
        alice.follow(bob)
        expect(alice.following?(bob)).to be true
      end
    end

    describe "#followers_count / #following_count" do
      before do
        alice.follow(bob)
        bob.follow(alice)
      end

      it "counts followers" do
        expect(alice.followers_count).to eq(1)
      end

      it "counts following" do
        expect(alice.following_count).to eq(1)
      end
    end

    describe "#display_name" do
      it "returns the username" do
        expect(alice.display_name).to eq(alice.username)
      end
    end
  end
end
