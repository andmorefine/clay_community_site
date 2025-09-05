require 'rails_helper'

RSpec.describe PostTag, type: :model do
  describe 'validations' do
    let(:post) { create(:post) }
    let(:tag) { create(:tag) }
    
    it 'validates uniqueness of post_id scoped to tag_id' do
      create(:post_tag, post: post, tag: tag)
      duplicate_post_tag = build(:post_tag, post: post, tag: tag)
      
      expect(duplicate_post_tag).not_to be_valid
      expect(duplicate_post_tag.errors[:post_id]).to include('already has this tag')
    end
    
    it 'allows the same post to have different tags' do
      tag2 = create(:tag)
      
      create(:post_tag, post: post, tag: tag)
      post_tag2 = build(:post_tag, post: post, tag: tag2)
      
      expect(post_tag2).to be_valid
    end
    
    it 'allows different posts to have the same tag' do
      post2 = create(:post)
      
      create(:post_tag, post: post, tag: tag)
      post_tag2 = build(:post_tag, post: post2, tag: tag)
      
      expect(post_tag2).to be_valid
    end
  end
  
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:tag) }
  end
  
  describe 'scopes' do
    let!(:old_post_tag) { create(:post_tag, created_at: 2.days.ago) }
    let!(:new_post_tag) { create(:post_tag, created_at: 1.day.ago) }
    
    describe '.recent' do
      it 'orders post_tags by creation date descending' do
        expect(PostTag.recent.first).to eq(new_post_tag)
      end
    end
    
    describe '.by_post' do
      let(:post) { create(:post) }
      let!(:post_post_tag) { create(:post_tag, post: post) }
      
      it 'returns post_tags for specified post' do
        expect(PostTag.by_post(post)).to include(post_post_tag)
        expect(PostTag.by_post(post)).not_to include(old_post_tag)
      end
    end
    
    describe '.by_tag' do
      let(:tag) { create(:tag) }
      let!(:tag_post_tag) { create(:post_tag, tag: tag) }
      
      it 'returns post_tags for specified tag' do
        expect(PostTag.by_tag(tag)).to include(tag_post_tag)
        expect(PostTag.by_tag(tag)).not_to include(old_post_tag)
      end
    end
  end
  
  describe '#tag_name' do
    it 'returns the name of the associated tag' do
      tag = create(:tag, name: 'clay')
      post_tag = create(:post_tag, tag: tag)
      expect(post_tag.tag_name).to eq('clay')
    end
  end
  
  describe '#post_title' do
    it 'returns the title of the associated post' do
      post = create(:post, title: 'My Clay Creation')
      post_tag = create(:post_tag, post: post)
      expect(post_tag.post_title).to eq('My Clay Creation')
    end
  end
end