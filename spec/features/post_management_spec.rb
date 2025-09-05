require 'rails_helper'

RSpec.feature "Post Management", type: :feature do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser', email: 'other@example.com') }

  before do
    # Mock authentication for feature tests
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
  end

  describe "Creating a post" do
    scenario "User creates a regular post successfully" do
      visit new_post_path

      fill_in "Title", with: "My Beautiful Clay Vase"
      fill_in "Description", with: "This is a handmade ceramic vase using traditional techniques."
      choose "Regular Post"
      fill_in "Tags", with: "pottery, ceramic, vase"
      check "Publish immediately"

      # Note: File upload testing would require additional setup with Capybara
      # For now, we'll test the form submission without file upload

      click_button "Create Post"

      expect(page).to have_content("Post was successfully created")
      expect(page).to have_content("My Beautiful Clay Vase")
      expect(page).to have_content("This is a handmade ceramic vase")
      expect(page).to have_content("Regular")
    end

    scenario "User creates a tutorial post with difficulty level" do
      visit new_post_path

      fill_in "Title", with: "How to Make a Clay Bowl"
      fill_in "Description", with: "Step-by-step guide to creating your first clay bowl."
      choose "Tutorial"
      select "Beginner", from: "Difficulty Level"
      fill_in "Tags", with: "tutorial, bowl, beginner"

      click_button "Create Post"

      expect(page).to have_content("Post was successfully created")
      expect(page).to have_content("How to Make a Clay Bowl")
      expect(page).to have_content("Tutorial")
      expect(page).to have_content("Beginner")
    end

    scenario "User cannot create post without required fields" do
      visit new_post_path

      click_button "Create Post"

      expect(page).to have_content("Please fix the following errors")
      expect(page).to have_content("Title can't be blank")
      expect(page).to have_content("Description can't be blank")
    end

    scenario "Tutorial post requires difficulty level" do
      visit new_post_path

      fill_in "Title", with: "Advanced Glazing Techniques"
      fill_in "Description", with: "Learn advanced glazing methods."
      choose "Tutorial"
      # Don't select difficulty level

      click_button "Create Post"

      expect(page).to have_content("Difficulty level must be specified for tutorial posts")
    end
  end

  describe "Viewing posts" do
    let!(:regular_post) { create(:post, user: user, title: "Regular Clay Work", post_type: :regular) }
    let!(:tutorial_post) { create(:post, user: user, title: "Clay Tutorial", post_type: :tutorial, difficulty_level: :intermediate) }
    let!(:tag) { create(:tag, name: "pottery") }

    before do
      regular_post.tags << tag
      tutorial_post.tags << tag
    end

    scenario "User views all posts on gallery page" do
      visit posts_path

      expect(page).to have_content("Clay Community Gallery")
      expect(page).to have_content("Regular Clay Work")
      expect(page).to have_content("Clay Tutorial")
      expect(page).to have_content("Regular")
      expect(page).to have_content("Tutorial")
    end

    scenario "User filters posts by type" do
      visit posts_path

      click_link "Tutorials"

      expect(page).to have_content("Clay Tutorial")
      expect(page).not_to have_content("Regular Clay Work")
    end

    scenario "User filters posts by tag" do
      visit posts_path

      click_link "#pottery"

      expect(page).to have_content("Regular Clay Work")
      expect(page).to have_content("Clay Tutorial")
    end

    scenario "User views individual post" do
      visit post_path(regular_post)

      expect(page).to have_content("Regular Clay Work")
      expect(page).to have_content(regular_post.description)
      expect(page).to have_content("by #{user.username}")
      expect(page).to have_content("#pottery")
    end
  end

  describe "Editing posts" do
    let!(:post) { create(:post, user: user, title: "Original Title") }

    scenario "Post owner can edit their post" do
      visit post_path(post)

      click_link "Edit"

      fill_in "Title", with: "Updated Title"
      fill_in "Description", with: "Updated description"

      click_button "Update Post"

      expect(page).to have_content("Post was successfully updated")
      expect(page).to have_content("Updated Title")
      expect(page).to have_content("Updated description")
    end

    scenario "Non-owner cannot see edit link" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)

      visit post_path(post)

      expect(page).not_to have_link("Edit")
    end

    scenario "Non-owner cannot access edit page directly" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)

      visit edit_post_path(post)

      expect(page).to have_content("You are not authorized")
      expect(current_path).to eq(posts_path)
    end
  end

  describe "Deleting posts" do
    let!(:post) { create(:post, user: user, title: "Post to Delete") }

    scenario "Post owner can delete their post" do
      visit post_path(post)

      accept_confirm do
        click_link "Delete"
      end

      expect(page).to have_content("Post was successfully deleted")
      expect(current_path).to eq(posts_path)
      expect(page).not_to have_content("Post to Delete")
    end

    scenario "Non-owner cannot see delete link" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(other_user)

      visit post_path(post)

      expect(page).not_to have_link("Delete")
    end
  end

  describe "Post interactions" do
    let!(:post) { create(:post, user: other_user, title: "Likeable Post") }

    scenario "User can like a post", js: true do
      visit post_path(post)

      expect(page).to have_content("0") # Initial like count

      # Note: This would require JavaScript testing setup
      # For now, we'll test the basic presence of like button
      expect(page).to have_css("#like-button")
    end

    scenario "User can comment on a post" do
      visit post_path(post)

      fill_in "Share your thoughts", with: "Great work! Love the technique."
      click_button "Post Comment"

      expect(page).to have_content("Comment was successfully added")
      expect(page).to have_content("Great work! Love the technique.")
      expect(page).to have_content("by #{user.username}")
    end

    scenario "User can delete their own comment" do
      comment = create(:comment, post: post, user: user, content: "My comment")

      visit post_path(post)

      expect(page).to have_content("My comment")

      accept_confirm do
        click_link "Delete"
      end

      expect(page).to have_content("Comment was successfully deleted")
      expect(page).not_to have_content("My comment")
    end
  end

  describe "Tag system" do
    let!(:post) { create(:post, user: user) }

    scenario "User can add tags when creating a post" do
      visit new_post_path

      fill_in "Title", with: "Tagged Post"
      fill_in "Description", with: "A post with tags"
      fill_in "Tags", with: "pottery, ceramic, handmade"

      click_button "Create Post"

      expect(page).to have_content("#pottery")
      expect(page).to have_content("#ceramic")
      expect(page).to have_content("#handmade")
    end

    scenario "User can update tags when editing a post" do
      post.add_tags("oldtag")

      visit edit_post_path(post)

      fill_in "Tags", with: "newtag, updated"

      click_button "Update Post"

      expect(page).to have_content("#newtag")
      expect(page).to have_content("#updated")
      expect(page).not_to have_content("#oldtag")
    end
  end

  describe "Post validation" do
    scenario "Title cannot be too long" do
      visit new_post_path

      fill_in "Title", with: "a" * 101 # Exceeds 100 character limit
      fill_in "Description", with: "Valid description"

      click_button "Create Post"

      expect(page).to have_content("Title is too long")
    end

    scenario "Description cannot be too long" do
      visit new_post_path

      fill_in "Title", with: "Valid Title"
      fill_in "Description", with: "a" * 2001 # Exceeds 2000 character limit

      click_button "Create Post"

      expect(page).to have_content("Description is too long")
    end
  end
end