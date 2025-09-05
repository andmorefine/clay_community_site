require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(1000) }
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end
  
  describe 'scopes' do
    let!(:old_comment) { create(:comment, created_at: 2.days.ago) }
    let!(:new_comment) { create(:comment, created_at: 1.day.ago) }
    
    describe '.recent' do
      it 'orders comments by creation date descending' do
        expect(Comment.recent.first).to eq(new_comment)
      end
    end
    
    describe '.oldest_first' do
      it 'orders comments by creation date ascending' do
        expect(Comment.oldest_first.first).to eq(old_comment)
      end
    end
    
    describe '.by_user' do
      let(:user) { create(:user) }
      let!(:user_comment) { create(:comment, user: user) }
      
      it 'returns comments by specified user' do
        expect(Comment.by_user(user)).to include(user_comment)
        expect(Comment.by_user(user)).not_to include(old_comment)
      end
    end
    
    describe '.for_post' do
      let(:post) { create(:post) }
      let!(:post_comment) { create(:comment, post: post) }
      
      it 'returns comments for specified post' do
        expect(Comment.for_post(post)).to include(post_comment)
        expect(Comment.for_post(post)).not_to include(old_comment)
      end
    end
  end
  
  describe '#author_name' do
    it 'returns the display name of the comment author' do
      user = create(:user, username: 'testuser')
      comment = create(:comment, user: user)
      expect(comment.author_name).to eq('testuser')
    end
  end
  
  describe '#can_be_deleted_by?' do
    let(:comment_author) { create(:user) }
    let(:post_author) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post) { create(:post, user: post_author) }
    let(:comment) { create(:comment, user: comment_author, post: post) }
    
    context 'when current user is the comment author' do
      it 'returns true' do
        expect(comment.can_be_deleted_by?(comment_author)).to be true
      end
    end
    
    context 'when current user is the post author' do
      it 'returns true' do
        expect(comment.can_be_deleted_by?(post_author)).to be true
      end
    end
    
    context 'when current user is neither comment nor post author' do
      it 'returns false' do
        expect(comment.can_be_deleted_by?(other_user)).to be false
      end
    end
    
    context 'when current user is nil' do
      it 'returns false' do
        expect(comment.can_be_deleted_by?(nil)).to be false
      end
    end
  end
  
  describe '#formatted_created_at' do
    it 'returns formatted creation date' do
      comment = create(:comment, created_at: Time.zone.parse('2023-12-25 14:30:00'))
      expect(comment.formatted_created_at).to eq('December 25, 2023 at 02:30 PM')
    end
  end
  
  describe '#time_ago' do
    let(:comment) { create(:comment) }
    
    context 'when comment was created less than a minute ago' do
      before { comment.update(created_at: 30.seconds.ago) }
      
      it 'returns seconds ago' do
        expect(comment.time_ago).to match(/\d+ seconds ago/)
      end
    end
    
    context 'when comment was created less than an hour ago' do
      before { comment.update(created_at: 30.minutes.ago) }
      
      it 'returns minutes ago' do
        expect(comment.time_ago).to match(/\d+ minutes ago/)
      end
    end
    
    context 'when comment was created less than a day ago' do
      before { comment.update(created_at: 5.hours.ago) }
      
      it 'returns hours ago' do
        expect(comment.time_ago).to match(/\d+ hours ago/)
      end
    end
    
    context 'when comment was created less than a month ago' do
      before { comment.update(created_at: 5.days.ago) }
      
      it 'returns days ago' do
        expect(comment.time_ago).to match(/\d+ days ago/)
      end
    end
    
    context 'when comment was created more than a month ago' do
      before { comment.update(created_at: 2.months.ago) }
      
      it 'returns formatted date' do
        expect(comment.time_ago).to match(/\w+ \d+, \d+ at \d+:\d+ \w+/)
      end
    end
  end
end