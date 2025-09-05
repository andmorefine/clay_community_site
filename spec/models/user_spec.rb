require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_length_of(:username).is_at_least(3).is_at_most(50) }
    it { should validate_inclusion_of(:skill_level).in_array(%w[beginner intermediate advanced expert]) }
    it { should validate_length_of(:bio).is_at_most(500) }
    
    it 'validates email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
    
    it 'validates username format' do
      user = build(:user, username: 'invalid-username!')
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include('can only contain letters, numbers, and underscores')
    end
  end
  
  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:liked_posts).through(:likes) }
    it { should have_many(:follows).dependent(:destroy) }
    it { should have_many(:followed_users).through(:follows) }
    it { should have_many(:reverse_follows).dependent(:destroy) }
    it { should have_many(:followers).through(:reverse_follows) }
    it 'has one attached profile image' do
      expect(User.new).to respond_to(:profile_image)
    end
  end
  
  describe 'callbacks' do
    it 'downcases email before saving' do
      user = create(:user, email: 'TEST@EXAMPLE.COM')
      expect(user.email).to eq('test@example.com')
    end
    
    it 'downcases username before saving' do
      user = create(:user, username: 'TestUser')
      expect(user.username).to eq('testuser')
    end
  end
  
  describe 'scopes' do
    let!(:beginner_user) { create(:user, skill_level: 'beginner') }
    let!(:expert_user) { create(:user, skill_level: 'expert') }
    
    describe '.by_skill_level' do
      it 'returns users with specified skill level' do
        expect(User.by_skill_level('beginner')).to include(beginner_user)
        expect(User.by_skill_level('beginner')).not_to include(expert_user)
      end
    end
    
    describe '.recent' do
      it 'orders users by creation date descending' do
        expect(User.recent.first).to eq(expert_user)
      end
    end
  end
  
  describe 'following functionality' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    
    describe '#follow' do
      it 'creates a follow relationship' do
        expect { user1.follow(user2) }.to change { user1.follows.count }.by(1)
        expect(user1.following?(user2)).to be true
      end
      
      it 'does not allow self-following' do
        result = user1.follow(user1)
        expect(result).to be false
      end
      
      it 'does not create duplicate follows' do
        user1.follow(user2)
        expect { user1.follow(user2) }.not_to change { user1.follows.count }
      end
    end
    
    describe '#unfollow' do
      before { user1.follow(user2) }
      
      it 'removes the follow relationship' do
        expect { user1.unfollow(user2) }.to change { user1.follows.count }.by(-1)
        expect(user1.following?(user2)).to be false
      end
    end
    
    describe '#following?' do
      it 'returns true when following the user' do
        user1.follow(user2)
        expect(user1.following?(user2)).to be true
      end
      
      it 'returns false when not following the user' do
        expect(user1.following?(user2)).to be false
      end
    end
  end
  
  describe 'counter methods' do
    let(:user) { create(:user) }
    let(:follower) { create(:user) }
    
    before do
      follower.follow(user)
      create_list(:post, 3, user: user, published: true)
      create(:post, user: user, published: false)
    end
    
    describe '#followers_count' do
      it 'returns the correct number of followers' do
        expect(user.followers_count).to eq(1)
      end
    end
    
    describe '#following_count' do
      it 'returns the correct number of followed users' do
        user.follow(follower)
        expect(user.following_count).to eq(1)
      end
    end
    
    describe '#posts_count' do
      it 'returns only published posts count' do
        expect(user.posts_count).to eq(3)
      end
    end
  end
  
  describe '#display_name' do
    it 'returns the username' do
      user = create(:user, username: 'testuser')
      expect(user.display_name).to eq('testuser')
    end
  end
end