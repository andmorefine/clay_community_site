module AuthenticationHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password123'
    click_button 'Sign in'
    
    # Debug: Check if there are any error messages
    if page.has_text?('Invalid email or password')
      puts "Sign in failed: Invalid credentials"
      puts "Page content: #{page.body}" if ENV['DEBUG']
    end
    
    # Check if we're still on the sign in page (which would indicate failure)
    if current_path == new_session_path
      puts "Still on sign in page - authentication failed"
      puts "Page content: #{page.body}" if ENV['DEBUG']
    end
    
    # Verify sign in was successful by checking navigation
    expect(page).not_to have_link('Sign In')
    expect(page).to have_text(user.username) # Should appear in navigation dropdown
  end
  
  def sign_out
    click_link 'Sign Out' if page.has_link?('Sign Out')
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :feature
end