require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    subject { build(:tag) }
    
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(50) }
    
    it 'validates name format' do
      valid_names = ['clay', 'pottery-art', 'ceramic_work', 'hand made']
      invalid_names = ['clay!', 'pottery@art', 'ceramic#work']
      
      valid_names.each do |name|
        tag = build(:tag, name: name)
        expect(tag).to be_valid, "Expected '#{name}' to be valid"
      end
      
      invalid_names.each do |name|
        tag = build(:tag, name: name)
        expect(tag).not_to be_valid, "Expected '#{name}' to be invalid"
        expect(tag.errors[:name]).to include('can only contain letters, numbers, hyphens, underscores, and spaces')
      end
    end
  end
  
  describe 'associations' do
    it { should have_many(:post_tags).dependent(:destroy) }
    it { should have_many(:posts).through(:post_tags) }
  end
  
  describe 'callbacks' do
    it 'normalizes name before saving' do
      tag = create(:tag, name: '  Clay Pottery  ')
      expect(tag.name).to eq('clay pottery')
    end
    
    it 'downcases name before saving' do
      tag = create(:tag, name: 'CLAY')
      expect(tag.name).to eq('clay')
    end
  end
  
  describe 'scopes' do
    let!(:tag1) { create(:tag, name: 'clay', created_at: 2.days.ago) }
    let!(:tag2) { create(:tag, name: 'pottery', created_at: 1.day.ago) }
    let!(:tag3) { create(:tag, name: 'ceramic') }
    
    before do
      # Create posts with tags to test popular scope
      post1 = create(:post)
      post2 = create(:post)
      post3 = create(:post)
      
      # tag1 has 2 posts, tag2 has 1 post, tag3 has 0 posts
      create(:post_tag, post: post1, tag: tag1)
      create(:post_tag, post: post2, tag: tag1)
      create(:post_tag, post: post3, tag: tag2)
    end
    
    describe '.popular' do
      it 'orders tags by post count descending' do
        popular_tags = Tag.popular.limit(2)
        expect(popular_tags.first).to eq(tag1)
        expect(popular_tags.second).to eq(tag2)
      end
    end
    
    describe '.alphabetical' do
      it 'orders tags alphabetically by name' do
        alphabetical_tags = Tag.alphabetical
        expect(alphabetical_tags.map(&:name)).to eq(['ceramic', 'clay', 'pottery'])
      end
    end
    
    describe '.recent' do
      it 'orders tags by creation date descending' do
        expect(Tag.recent.first).to eq(tag3)
      end
    end
    
    describe '.with_posts' do
      it 'returns only tags that have posts' do
        tags_with_posts = Tag.with_posts
        expect(tags_with_posts).to include(tag1, tag2)
        expect(tags_with_posts).not_to include(tag3)
      end
    end
  end
  
  describe 'instance methods' do
    let(:tag) { create(:tag, name: 'clay') }
    
    describe '#posts_count' do
      it 'returns the count of published posts with this tag' do
        published_post = create(:post, published: true)
        unpublished_post = create(:post, published: false)
        
        create(:post_tag, post: published_post, tag: tag)
        create(:post_tag, post: unpublished_post, tag: tag)
        
        expect(tag.posts_count).to eq(1)
      end
    end
    
    describe '#display_name' do
      it 'returns titleized name' do
        tag = create(:tag, name: 'clay pottery')
        expect(tag.display_name).to eq('Clay Pottery')
      end
    end
    
    describe '#to_param' do
      it 'returns the tag name for URL generation' do
        expect(tag.to_param).to eq('clay')
      end
    end
  end
  
  describe 'class methods' do
    describe '.find_by_name' do
      let!(:tag) { create(:tag, name: 'clay') }
      
      it 'finds tag by normalized name' do
        expect(Tag.find_by_name('CLAY')).to eq(tag)
        expect(Tag.find_by_name('  clay  ')).to eq(tag)
      end
      
      it 'returns nil for non-existent tag' do
        expect(Tag.find_by_name('nonexistent')).to be_nil
      end
    end
    
    describe '.create_or_find_by_name' do
      it 'creates a new tag if it does not exist' do
        expect { Tag.create_or_find_by_name('new_tag') }.to change { Tag.count }.by(1)
        expect(Tag.find_by(name: 'new_tag')).to be_present
      end
      
      it 'finds existing tag if it exists' do
        existing_tag = create(:tag, name: 'existing')
        found_tag = Tag.create_or_find_by_name('EXISTING')
        expect(found_tag).to eq(existing_tag)
      end
    end
    
    describe '.popular_tags' do
      let!(:popular_tag) { create(:tag, name: 'popular') }
      let!(:unpopular_tag) { create(:tag, name: 'unpopular') }
      
      before do
        post = create(:post)
        create(:post_tag, post: post, tag: popular_tag)
      end
      
      it 'returns limited number of popular tags' do
        popular_tags = Tag.popular_tags(1)
        expect(popular_tags).to include(popular_tag)
        expect(popular_tags).not_to include(unpopular_tag)
        expect(popular_tags.size).to eq(1)
      end
    end
    
    describe '.search' do
      let!(:clay_tag) { create(:tag, name: 'clay') }
      let!(:pottery_tag) { create(:tag, name: 'pottery') }
      let!(:ceramic_tag) { create(:tag, name: 'ceramic') }
      
      it 'returns tags matching the search query' do
        results = Tag.search('cla')
        expect(results).to include(clay_tag)
        expect(results).not_to include(pottery_tag, ceramic_tag)
      end
      
      it 'is case insensitive' do
        results = Tag.search('CLA')
        expect(results).to include(clay_tag)
      end
    end
  end
end