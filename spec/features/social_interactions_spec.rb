require 'rails_helper'

RSpec.feature 'Social Interactions', type: :feature, js: true do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser', email: 'other@example.com') }
  let(:post_record) { create(:post, user: other_user) }

  before do
    # Mock authentication for feature tests
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
  end

  describe 'Liking posts' do
    scenario 'User can like a post from the post show page' do
      visit post_path(post_record)
      
      expect(page).to have_content('0') # Initial like count
      expect(page).to have_content('🤍') # Empty heart
      
      # Click like button
      find('[data-social-target="likeButton"]').click
      
      # Wait for AJAX response
      expect(page).to have_content('1') # Updated like count
      expect(page).to have_content('❤️') # Filled heart
      
      # Verify like was created in database
      expect(post_record.reload.likes_count).to eq(1)
      expect(post_record.liked_by?(user)).to be true
    end

    scenario 'User can unlike a post' do
      # Create initial like
      post_record.likes.create!(user: user)
      
      visit post_path(post_record)
      
      expect(page).to have_content('1') # Initial like count
      expect(page).to have_content('❤️') # Filled heart
      
      # Click unlike button
      find('[data-social-target="likeButton"]').click
      
      # Wait for AJAX response
      expect(page).to have_content('0') # Updated like count
      expect(page).to have_content('🤍') # Empty heart
      
      # Verify like was removed from database
      expect(post_record.reload.likes_count).to eq(0)
      expect(post_record.liked_by?(user)).to be false
    end

    scenario 'User can like a post from the gallery page' do
      visit posts_path
      
      # Find the post card and like button
      post_card = find("[data-social-post-id-value='#{post_record.id}']")
      
      within(post_card) do
        expect(page).to have_content('0') # Initial like count
        expect(page).to have_content('🤍') # Empty heart
        
        # Click like button
        find('[data-social-target="likeButton"]').click
        
        # Wait for AJAX response
        expect(page).to have_content('1') # Updated like count
        expect(page).to have_content('❤️') # Filled heart
      end
      
      # Verify like was created in database
      expect(post_record.reload.likes_count).to eq(1)
      expect(post_record.liked_by?(user)).to be true
    end
  end

  describe 'Commenting on posts' do
    scenario 'User can add a comment to a post' do
      visit post_path(post_record)
      
      expect(page).to have_content('Comments (0)')
      
      # Fill in comment form
      fill_in 'comment[content]', with: 'This is a great clay creation!'
      click_button 'Post Comment'
      
      # Should redirect and show the comment
      expect(page).to have_content('Comments (1)')
      expect(page).to have_content('This is a great clay creation!')
      expect(page).to have_content(user.username)
      
      # Verify comment was created in database
      expect(post_record.reload.comments_count).to eq(1)
      expect(post_record.comments.last.content).to eq('This is a great clay creation!')
      expect(post_record.comments.last.user).to eq(user)
    end

    scenario 'User can delete their own comment' do
      # Create initial comment
      comment = post_record.comments.create!(user: user, content: 'My test comment')
      
      visit post_path(post_record)
      
      expect(page).to have_content('Comments (1)')
      expect(page).to have_content('My test comment')
      
      # Find and click delete button
      within('.comment-item') do
        find('[title="Delete comment"]').click
      end
      
      # Confirm deletion in the browser dialog
      page.driver.browser.switch_to.alert.accept
      
      # Comment should be removed
      expect(page).not_to have_content('My test comment')
      
      # Verify comment was deleted from database
      expect(post_record.reload.comments_count).to eq(0)
      expect(Comment.exists?(comment.id)).to be false
    end

    scenario 'User cannot delete other users comments' do
      # Create comment by other user
      comment = post_record.comments.create!(user: other_user, content: 'Other user comment')
      
      visit post_path(post_record)
      
      expect(page).to have_content('Comments (1)')
      expect(page).to have_content('Other user comment')
      
      # Delete button should not be visible
      within('.comment-item') do
        expect(page).not_to have_css('[title="Delete comment"]')
      end
    end

    scenario 'Post owner can delete any comment on their post' do
      # Visit as post owner
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)
      
      # Create comment by different user
      comment = post_record.comments.create!(user: user, content: 'Comment by other user')
      
      visit post_path(post_record)
      
      expect(page).to have_content('Comments (1)')
      expect(page).to have_content('Comment by other user')
      
      # Delete button should be visible to post owner
      within('.comment-item') do
        expect(page).to have_css('[title="Delete comment"]')
        find('[title="Delete comment"]').click
      end
      
      # Confirm deletion
      page.driver.browser.switch_to.alert.accept
      
      # Comment should be removed
      expect(page).not_to have_content('Comment by other user')
      
      # Verify comment was deleted from database
      expect(post_record.reload.comments_count).to eq(0)
      expect(Comment.exists?(comment.id)).to be false
    end
  end

  describe 'Real-time updates' do
    scenario 'Like count updates are reflected immediately' do
      visit post_path(post_record)
      
      # Initial state
      expect(page).to have_content('0')
      
      # Like the post
      find('[data-social-target="likeButton"]').click
      
      # Should update immediately without page refresh
      expect(page).to have_content('1')
      
      # Unlike the post
      find('[data-social-target="likeButton"]').click
      
      # Should update immediately
      expect(page).to have_content('0')
    end

    scenario 'Error handling for failed like requests' do
      # Mock a failed request
      allow_any_instance_of(PostsController).to receive(:like).and_raise(StandardError)
      
      visit post_path(post_record)
      
      # Try to like the post
      find('[data-social-target="likeButton"]').click
      
      # Should show error notification
      expect(page).to have_content('Failed to update like')
      
      # Should revert optimistic update
      expect(page).to have_content('0')
      expect(page).to have_content('🤍')
    end
  end

  describe 'Comment validation' do
    scenario 'User cannot submit empty comment' do
      visit post_path(post_record)
      
      # Try to submit empty comment
      click_button 'Post Comment'
      
      # Should show validation error or not submit
      expect(page).to have_content('Comments (0)')
      expect(post_record.reload.comments_count).to eq(0)
    end

    scenario 'User cannot submit comment that is too long' do
      visit post_path(post_record)
      
      # Fill in very long comment
      long_comment = 'a' * 1001 # Exceeds 1000 character limit
      fill_in 'comment[content]', with: long_comment
      click_button 'Post Comment'
      
      # Should show validation error
      expect(page).to have_content('Comments (0)')
      expect(post_record.reload.comments_count).to eq(0)
    end
  end
end