require 'rails_helper'

RSpec.describe SpamDetectionService do
  describe '.check_content' do
    it 'returns low score for normal content' do
      result = SpamDetectionService.check_content("This is a normal post about clay pottery")
      
      expect(result[:spam]).to be false
      expect(result[:score]).to be < 5
      expect(result[:confidence]).to eq('low')
    end

    it 'detects spam keywords' do
      result = SpamDetectionService.check_content("Buy now! Click here for free money!")
      
      expect(result[:spam]).to be true
      expect(result[:score]).to be >= 5
      expect(result[:reasons]).to include("Contains spam keyword: buy now")
    end

    it 'detects excessive links' do
      content = "Check out https://example.com and https://test.com and https://spam.com"
      result = SpamDetectionService.check_content(content)
      
      expect(result[:score]).to be > 0
      expect(result[:reasons]).to include("Contains multiple links (3)")
    end

    it 'detects excessive exclamation marks' do
      result = SpamDetectionService.check_content("Amazing deal!!!! Don't miss out!!!!")
      
      expect(result[:score]).to be > 0
      expect(result[:reasons]).to include("Excessive exclamation marks (8)")
    end

    it 'returns empty result for blank content' do
      result = SpamDetectionService.check_content("")
      
      expect(result[:spam]).to be false
      expect(result[:score]).to eq(0)
      expect(result[:reasons]).to be_empty
    end
  end

  describe '.check_user_behavior' do
    let(:user) { create(:user) }

    it 'returns low score for normal user' do
      result = SpamDetectionService.check_user_behavior(user)
      
      expect(result[:suspicious]).to be false
      expect(result[:score]).to be < 7
    end

    it 'detects high posting frequency' do
      allow(user).to receive_message_chain(:posts, :where, :count).and_return(10)
      
      result = SpamDetectionService.check_user_behavior(user)
      
      expect(result[:score]).to be > 0
      expect(result[:reasons]).to include("High posting frequency (10 posts in last hour)")
    end

    it 'detects new accounts' do
      new_user = create(:user, created_at: 1.hour.ago)
      
      result = SpamDetectionService.check_user_behavior(new_user)
      
      expect(result[:score]).to be >= 3
      expect(result[:reasons]).to include(a_string_matching(/New account/))
    end

    it 'considers warning count' do
      user.update!(warning_count: 2)
      
      result = SpamDetectionService.check_user_behavior(user)
      
      expect(result[:score]).to be >= 4
      expect(result[:reasons]).to include("Previous warnings (2)")
    end
  end

  describe '.auto_moderate_content' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user) }

    it 'flags high-score content' do
      allow(SpamDetectionService).to receive(:check_content).and_return({
        spam: true, score: 8, reasons: ['spam detected']
      })
      allow(SpamDetectionService).to receive(:check_user_behavior).and_return({
        suspicious: false, score: 2, reasons: []
      })

      result = SpamDetectionService.auto_moderate_content(post, user)
      
      expect(result[:action]).to eq('flagged')
      expect(result[:score]).to eq(10)
    end

    it 'requires review for medium-score content' do
      allow(SpamDetectionService).to receive(:check_content).and_return({
        spam: false, score: 4, reasons: []
      })
      allow(SpamDetectionService).to receive(:check_user_behavior).and_return({
        suspicious: false, score: 4, reasons: []
      })

      result = SpamDetectionService.auto_moderate_content(post, user)
      
      expect(result[:action]).to eq('review_required')
      expect(result[:score]).to eq(8)
    end

    it 'approves low-score content' do
      allow(SpamDetectionService).to receive(:check_content).and_return({
        spam: false, score: 1, reasons: []
      })
      allow(SpamDetectionService).to receive(:check_user_behavior).and_return({
        suspicious: false, score: 1, reasons: []
      })

      result = SpamDetectionService.auto_moderate_content(post, user)
      
      expect(result[:action]).to eq('approved')
      expect(result[:score]).to eq(2)
    end
  end
end