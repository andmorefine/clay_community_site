require 'rails_helper'

RSpec.describe Appeal, type: :model do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, role: 'moderator') }
  let(:moderation_action) { create(:moderation_action, user: user, moderator: moderator) }
  let(:appeal) { create(:appeal, user: user, moderation_action: moderation_action) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:moderation_action) }
    it { should belong_to(:reviewed_by).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:reason) }
    it { should validate_length_of(:reason).is_at_most(1000) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, under_review: 1, approved: 2, denied: 3) }
  end

  describe 'scopes' do
    let!(:pending_appeal) { create(:appeal, status: :pending) }
    let!(:approved_appeal) { create(:appeal, status: :approved) }

    it 'returns unresolved appeals' do
      expect(Appeal.unresolved).to include(pending_appeal)
      expect(Appeal.unresolved).not_to include(approved_appeal)
    end

    it 'returns recent appeals' do
      expect(Appeal.recent.first).to eq(approved_appeal)
    end
  end

  describe '#resolve!' do
    let(:reviewer) { create(:user, role: 'moderator') }

    it 'resolves the appeal' do
      appeal.resolve!(reviewer, 'approved')
      
      expect(appeal.status).to eq('approved')
      expect(appeal.reviewed_by).to eq(reviewer)
      expect(appeal.reviewed_at).to be_present
    end
  end
end
