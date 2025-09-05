require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    
    it 'validates uniqueness of follower_id scoped to followed_id' do
      create(:follow, follower: user1, followed: user2)
      duplicate_follow = build(:follow, follower: user1, followed: user2)
      
      expect(duplicate_follow).not_to be_valid
      expect(duplicate_follow.errors[:follower_id]).to include('is already following this user')
    end
    
    it 'allows the same user to follow different users' do
      user3 = create(:user)
      
      create(:follow, follower: user1, followed: user2)
      follow2 = build(:follow, follower: user1, followed: user3)
      
      expect(follow2).to be_valid
    end
    
    it 'allows different users to follow the same user' do
      user3 = create(:user)
      
      create(:follow, follower: user1, followed: user2)
      follow2 = build(:follow, follower: user3, followed: user2)
      
      expect(follow2).to be_valid
    end
    
    it 'prevents users from following themselves' do
      self_follow = build(:follow, follower: user1, followed: user1)
      
      expect(self_follow).not_to be_valid
      expect(self_follow.errors[:followed]).to include('cannot follow yourself')
    end
  end
  
  describe 'associations' do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end
  
  describe 'scopes' do
    let!(:old_follow) { create(:follow, created_at: 2.days.ago) }
    let!(:new_follow) { create(:follow, created_at: 1.day.ago) }
    
    describe '.recent' do
      it 'orders follows by creation date descending' do
        expect(Follow.recent.first).to eq(new_follow)
      end
    end
    
    describe '.by_follower' do
      let(:user) { create(:user) }
      let!(:user_follow) { create(:follow, follower: user) }
      
      it 'returns follows by specified follower' do
        expect(Follow.by_follower(user)).to include(user_follow)
        expect(Follow.by_follower(user)).not_to include(old_follow)
      end
    end
    
    describe '.by_followed' do
      let(:user) { create(:user) }
      let!(:user_followed) { create(:follow, followed: user) }
      
      it 'returns follows for specified followed user' do
        expect(Follow.by_followed(user)).to include(user_followed)
        expect(Follow.by_followed(user)).not_to include(old_follow)
      end
    end
  end
  
  describe '#follower_name' do
    it 'returns the display name of the follower' do
      follower = create(:user, username: 'follower_user')
      follow = create(:follow, follower: follower)
      expect(follow.follower_name).to eq('follower_user')
    end
  end
  
  describe '#followed_name' do
    it 'returns the display name of the followed user' do
      followed = create(:user, username: 'followed_user')
      follow = create(:follow, followed: followed)
      expect(follow.followed_name).to eq('followed_user')
    end
  end
end