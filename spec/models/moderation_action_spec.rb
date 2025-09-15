require 'rails_helper'

RSpec.describe ModerationAction, type: :model do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, role: 'moderator') }
  let(:moderation_action) { create(:moderation_action, user: user, moderator: moderator) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:moderator) }
    it { should belong_to(:target) }
    it { should have_many(:appeals) }
  end

  describe 'validations' do
    it { should validate_presence_of(:action_type) }
    it { should validate_presence_of(:reason) }
    it { should validate_length_of(:reason).is_at_most(1000) }
  end

  describe 'enums' do
    it 'defines action_type enum' do
      expect(ModerationAction.action_types.keys).to include('warning', 'temporary_suspension', 'permanent_suspension', 'content_removal', 'content_approval')
    end
  end

  describe '#active?' do
    it 'returns true for actions without expiry' do
      action = create(:moderation_action, expires_at: nil)
      expect(action.active?).to be true
    end

    it 'returns true for actions with future expiry' do
      action = create(:moderation_action, expires_at: 1.day.from_now)
      expect(action.active?).to be true
    end

    it 'returns false for expired actions' do
      action = create(:moderation_action, expires_at: 1.day.ago)
      expect(action.active?).to be false
    end
  end
end
