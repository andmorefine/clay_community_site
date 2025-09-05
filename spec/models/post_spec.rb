require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'validations' do
    subject { build(:post) }
    
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_most(2000) }
    it 'validates post_type inclusion' do
      expect(build(:post, post_type: 'regular')).to be_valid
      expect(build(:post, post_type: 'tutorial', difficulty_level: 'beginner')).to be_valid
      
      expect { build(:post, post_type: 'invalid') }.to raise_error(ArgumentError)
    end
    
    context 'when post is a tutorial' do
      subject { build(:post, post_type: 'tutorial') }
      
      it 'requires difficulty_level' do
        subject.difficulty_level = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:difficulty_level]).to include('must be specified for tutorial posts')
      end
    end
    
    context 'when post is regular' do
      subject { build(:post, post_type: 'regular') }
      
      it 'does not require difficulty_level' do
        subject.difficulty_level = nil
        expect(subject).to be_valid
      end
    end
  end
  
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:liked_users).through(:likes) }
    it { should have_many(:post_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:post_tags) }
    it 'has many attached images' do
      expect(Post.new).to respond_to(:images)
    end
  end
  
  describe 'enums' do
    it { should define_enum_for(:post_type).with_values(regular: 0, tutorial: 1) }
    it { should define_enum_for(:difficulty_level).with_values(beginner: 0, intermediate: 1, advanced: 2, expert: 3) }
  end
  
  describe 'scopes' do
    let!(:published_post) { create(:post, published: true) }
    let!(:unpublished_post) { create(:post, published: false) }
    let!(:tutorial_post) { create(:post, post_type: 'tutorial', difficulty_level: 'beginner') }
    let!(:regular_post) { create(:post, post_type: 'regular') }
    
    describe '.published' do
      it 'returns only published posts' do
        expect(Post.published).to include(published_post)
        expect(Post.published).not_to include(unpublished_post)
      end
    end
    
    describe '.tutorials' do
      it 'returns only tutorial posts' do
        expect(Post.tutorials).to include(tutorial_post)
        expect(Post.tutorials).not_to include(regular_post)
      end
    end
    
    describe '.regular_posts' do
      it 'returns only regular posts' do
        expect(Post.regular_posts).to include(regular_post)
        expect(Post.regular_posts).not_to include(tutorial_post)
      end
    end
    
    describe '.recent' do
      it 'orders posts by creation date descending' do
        expect(Post.recent.first).to eq(regular_post)
      end
    end
    
    describe '.by_user' do
      let(:user) { create(:user) }
      let!(:user_post) { create(:post, user: user) }
      
      it 'returns posts by specified user' do
        expect(Post.by_user(user)).to include(user_post)
        expect(Post.by_user(user)).not_to include(published_post)
      end
    end
  end
  
  describe 'like functionality' do
    let(:post) { create(:post) }
    let(:user) { create(:user) }
    
    describe '#toggle_like' do
      context 'when user has not liked the post' do
        it 'creates a like and returns true' do
          expect { post.toggle_like(user) }.to change { post.likes.count }.by(1)
        end
        
        it 'returns true when liking' do
          result = post.toggle_like(user)
          expect(result).to be true
        end
      end
      
      context 'when user has already liked the post' do
        before { post.likes.create(user: user) }
        
        it 'removes the like and returns false' do
          expect { post.toggle_like(user) }.to change { post.likes.count }.by(-1)
        end
        
        it 'returns false when unliking' do
          result = post.toggle_like(user)
          expect(result).to be false
        end
      end
      
      context 'when user is nil' do
        it 'returns false and does not create a like' do
          expect { post.toggle_like(nil) }.not_to change { post.likes.count }
          expect(post.toggle_like(nil)).to be false
        end
      end
    end
    
    describe '#liked_by?' do
      context 'when user has liked the post' do
        before { post.likes.create(user: user) }
        
        it 'returns true' do
          expect(post.liked_by?(user)).to be true
        end
      end
      
      context 'when user has not liked the post' do
        it 'returns false' do
          expect(post.liked_by?(user)).to be false
        end
      end
      
      context 'when user is nil' do
        it 'returns false' do
          expect(post.liked_by?(nil)).to be false
        end
      end
    end
    
    describe '#likes_count' do
      it 'returns the correct number of likes' do
        create_list(:like, 3, post: post)
        expect(post.likes_count).to eq(3)
      end
    end
  end
  
  describe 'tag functionality' do
    let(:post) { create(:post) }
    
    describe '#add_tags' do
      context 'with string input' do
        it 'creates tags from comma-separated string' do
          post.add_tags('clay, pottery, ceramic')
          expect(post.tags.pluck(:name)).to match_array(['clay', 'pottery', 'ceramic'])
        end
      end
      
      context 'with array input' do
        it 'creates tags from array' do
          post.add_tags(['sculpture', 'art'])
          expect(post.tags.pluck(:name)).to match_array(['sculpture', 'art'])
        end
      end
      
      context 'with existing tags' do
        before { create(:tag, name: 'clay') }
        
        it 'uses existing tags instead of creating duplicates' do
          expect { post.add_tags('clay, pottery') }.to change { Tag.count }.by(1)
          expect(post.tags.pluck(:name)).to match_array(['clay', 'pottery'])
        end
      end
      
      context 'with blank input' do
        it 'does not create any tags' do
          expect { post.add_tags('') }.not_to change { post.tags.count }
          expect { post.add_tags(nil) }.not_to change { post.tags.count }
        end
      end
    end
    
    describe '#tag_names' do
      before do
        post.add_tags('clay, pottery, ceramic')
      end
      
      it 'returns comma-separated tag names' do
        expect(post.tag_names).to eq('clay, pottery, ceramic')
      end
    end
  end
  
  describe '#comments_count' do
    let(:post) { create(:post) }
    
    it 'returns the correct number of comments' do
      create_list(:comment, 2, post: post)
      expect(post.comments_count).to eq(2)
    end
  end
end