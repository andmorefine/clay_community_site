require 'rails_helper'

RSpec.feature "Gallery Browsing", type: :feature do
  let!(:user1) { create(:user, username: 'clay_artist_1') }
  let!(:user2) { create(:user, username: 'clay_artist_2') }
  
  let!(:tag_pottery) { create(:tag, name: 'pottery') }
  let!(:tag_sculpture) { create(:tag, name: 'sculpture') }
  let!(:tag_beginner) { create(:tag, name: 'beginner') }
  
  let!(:regular_post) do
    create(:post, 
           user: user1, 
           title: 'Beautiful Clay Vase',
           description: 'A handmade clay vase with intricate patterns',
           post_type: 'regular',
           published: true,
           tags: [tag_pottery])
  end
  
  let!(:tutorial_post) do
    create(:post,
           user: user2,
           title: 'How to Make a Clay Bowl',
           description: 'Step by step tutorial for beginners',
           post_type: 'tutorial',
           difficulty_level: 'beginner',
           published: true,
           tags: [tag_pottery, tag_beginner])
  end
  
  let!(:sculpture_post) do
    create(:post,
           user: user1,
           title: 'Abstract Clay Sculpture',
           description: 'Modern abstract sculpture made from clay',
           post_type: 'regular',
           published: true,
           tags: [tag_sculpture])
  end

  before do
    # Create some likes for testing popularity
    3.times { create(:like, post: regular_post, user: create(:user)) }
    1.times { create(:like, post: tutorial_post, user: create(:user)) }
    
    # Create some comments
    2.times { create(:comment, post: regular_post, user: create(:user)) }
    1.times { create(:comment, post: tutorial_post, user: create(:user)) }
  end

  scenario "User views the main gallery page" do
    visit posts_path
    
    expect(page).to have_content("Clay Community Gallery")
    expect(page).to have_content("3 creations shared by our community")
    
    # Check that all posts are displayed
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("How to Make a Clay Bowl")
    expect(page).to have_content("Abstract Clay Sculpture")
    
    # Check post metadata
    expect(page).to have_content("clay_artist_1")
    expect(page).to have_content("clay_artist_2")
    
    # Check post types are displayed
    expect(page).to have_content("Regular")
    expect(page).to have_content("Tutorial")
    
    # Check difficulty level for tutorial
    expect(page).to have_content("Beginner")
    
    # Check likes and comments count are displayed
    expect(page).to have_content("3") # regular_post likes
    expect(page).to have_content("2") # regular_post comments
  end

  scenario "User searches for posts" do
    visit posts_path
    
    fill_in "search", with: "vase"
    click_button "Search"
    
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).not_to have_content("How to Make a Clay Bowl")
    expect(page).not_to have_content("Abstract Clay Sculpture")
    
    # Check active filters display
    expect(page).to have_content("Active filters:")
    expect(page).to have_content("Search: vase")
  end

  scenario "User searches by username" do
    visit posts_path
    
    fill_in "search", with: "clay_artist_1"
    click_button "Search"
    
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("Abstract Clay Sculpture")
    expect(page).not_to have_content("How to Make a Clay Bowl")
  end

  scenario "User filters posts by type" do
    visit posts_path
    
    click_link "Tutorials"
    
    expect(page).to have_content("How to Make a Clay Bowl")
    expect(page).not_to have_content("Beautiful Clay Vase")
    expect(page).not_to have_content("Abstract Clay Sculpture")
    
    # Check that difficulty filter appears for tutorials
    expect(page).to have_link("Beginner")
    expect(page).to have_link("Intermediate")
    expect(page).to have_link("Advanced")
    expect(page).to have_link("Expert")
  end

  scenario "User filters tutorials by difficulty" do
    visit posts_path
    
    click_link "Tutorials"
    click_link "Beginner"
    
    expect(page).to have_content("How to Make a Clay Bowl")
    expect(page).to have_content("Active filters:")
    expect(page).to have_content("Post type: tutorial")
    expect(page).to have_content("Difficulty: beginner")
  end

  scenario "User filters posts by tag" do
    visit posts_path
    
    # Click on pottery tag
    click_link "#pottery"
    
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("How to Make a Clay Bowl")
    expect(page).not_to have_content("Abstract Clay Sculpture")
    
    expect(page).to have_content("Active filters:")
    expect(page).to have_content("Tag: pottery")
  end

  scenario "User sorts posts by different criteria" do
    visit posts_path
    
    # Test sorting by popularity
    select "❤️ Most Liked", from: "sort"
    
    # The regular_post should appear first (3 likes vs 1 like)
    posts = page.all('.grid article h3')
    expect(posts.first.text).to include("Beautiful Clay Vase")
    
    # Test sorting by trending
    select "🔥 Trending", from: "sort"
    
    # Should show posts from last 7 days sorted by popularity
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("How to Make a Clay Bowl")
    
    # Test sorting by most discussed
    select "💬 Most Discussed", from: "sort"
    
    # regular_post has more comments
    posts = page.all('.grid article h3')
    expect(posts.first.text).to include("Beautiful Clay Vase")
    
    # Test sorting by oldest
    select "📅 Oldest First", from: "sort"
    expect(current_url).to include("sort=oldest")
  end

  scenario "User clears active filters" do
    visit posts_path
    
    # Apply some filters
    fill_in "search", with: "vase"
    click_button "Search"
    
    click_link "Tutorials"
    
    expect(page).to have_content("Active filters:")
    
    # Clear all filters
    click_link "Clear all"
    
    expect(page).not_to have_content("Active filters:")
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("How to Make a Clay Bowl")
    expect(page).to have_content("Abstract Clay Sculpture")
  end

  scenario "User views empty state when no posts match filters" do
    visit posts_path
    
    fill_in "search", with: "nonexistent"
    click_button "Search"
    
    expect(page).to have_content("No posts match your filters")
    expect(page).to have_content("Try adjusting your search criteria")
    expect(page).to have_link("Clear Filters")
    expect(page).to have_link("Create New Post")
  end

  scenario "User navigates to post detail from gallery" do
    visit posts_path
    
    click_link "Beautiful Clay Vase"
    
    expect(page).to have_content("Beautiful Clay Vase")
    expect(page).to have_content("A handmade clay vase with intricate patterns")
    expect(page).to have_content("by clay_artist_1")
  end

  scenario "User views popular tags section" do
    visit posts_path
    
    expect(page).to have_content("Popular Tags")
    expect(page).to have_link("#pottery")
    expect(page).to have_link("#sculpture")
    expect(page).to have_link("#beginner")
    
    # Check tag post counts
    expect(page).to have_content("(2)") # pottery appears in 2 posts
    expect(page).to have_content("(1)") # sculpture and beginner appear in 1 post each
  end

  scenario "User views responsive grid layout", js: true do
    visit posts_path
    
    # Check that posts are displayed in a grid
    expect(page).to have_css('.grid')
    expect(page).to have_css('article', count: 3)
    
    # Check responsive classes are present
    expect(page).to have_css('.grid-cols-1')
    expect(page).to have_css('.sm\\:grid-cols-2')
    expect(page).to have_css('.lg\\:grid-cols-3')
  end

  context "with pagination" do
    before do
      # Create more posts to test pagination
      15.times do |i|
        create(:post, 
               user: user1, 
               title: "Test Post #{i + 4}",
               description: "Description for test post #{i + 4}",
               published: true)
      end
    end

    scenario "User navigates through paginated results" do
      visit posts_path
      
      # Should show pagination info
      expect(page).to have_content("Showing 1 to 12 of 18 posts")
      
      # Should have pagination controls
      expect(page).to have_css('nav[aria-label="Pagination"]')
      
      # Navigate to next page
      within('nav[aria-label="Pagination"]') do
        click_link "2"
      end
      
      expect(page).to have_content("Showing 13 to 18 of 18 posts")
    end
  end

  context "mobile responsive design" do
    before do
      # Simulate mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    scenario "User views gallery on mobile device", js: true do
      visit posts_path
      
      # Check mobile-specific elements
      expect(page).to have_css('.grid-cols-1')
      
      # Check that search form is responsive
      expect(page).to have_css('input[name="search"]')
      
      # Check that filters wrap properly on mobile
      expect(page).to have_css('.flex-wrap')
    end
  end

  context "with user authentication" do
    scenario "Authenticated user can create new post" do
      # This will be implemented when authentication is ready
      visit posts_path
      
      expect(page).to have_link("Create New Post")
    end
  end
end