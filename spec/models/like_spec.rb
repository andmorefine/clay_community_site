require 'rails_helper'

RSpec.describe Like, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:post) { create(:post) }
    
    it 'validates uniqueness of user_id scoped to post_id' do
      create(:like, user: user, post: post)
      duplicate_like = build(:like, user: user, post: post)
      
      expect(duplicate_like).not_to be_valid
      expect(duplicate_like.errors[:user_id]).to include('has already liked this post')
    end
    
    it 'allows the same user to like different posts' do
      post1 = create(:post)
      post2 = create(:post)
      
      create(:like, user: user, post: post1)
      like2 = build(:like, user: user, post: post2)
      
      expect(like2).to be_valid
    end
    
    it 'allows different users to like the same post' do
      user1 = create(:user)
      user2 = create(:user)
      
      create(:like, user: user1, post: post)
      like2 = build(:like, user: user2, post: post)
      
      expect(like2).to be_valid
    end
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end
  
  describe 'scopes' do
    let!(:old_like) { create(:like, created_at: 2.days.ago) }
    let!(:new_like) { create(:like, created_at: 1.day.ago) }
    
    describe '.recent' do
      it 'orders likes by creation date descending' do
        expect(Like.recent.first).to eq(new_like)
      end
    end
    
    describe '.by_user' do
      let(:user) { create(:user) }
      let!(:user_like) { create(:like, user: user) }
      
      it 'returns likes by specified user' do
        expect(Like.by_user(user)).to include(user_like)
        expect(Like.by_user(user)).not_to include(old_like)
      end
    end
    
    describe '.for_post' do
      let(:post) { create(:post) }
      let!(:post_like) { create(:like, post: post) }
      
      it 'returns likes for specified post' do
        expect(Like.for_post(post)).to include(post_like)
        expect(Like.for_post(post)).not_to include(old_like)
      end
    end
  end
  
  describe '#liker_name' do
    it 'returns the display name of the user who liked' do
      user = create(:user, username: 'testuser')
      like = create(:like, user: user)
      expect(like.liker_name).to eq('testuser')
    end
  end
end