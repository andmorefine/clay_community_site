require 'rails_helper'

RSpec.describe Report, type: :model do
  let(:user) { create(:user) }
  let(:post) { create(:post) }
  let(:report) { create(:report, user: user, reportable: post) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:reportable) }
    it { should belong_to(:resolved_by).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:reason) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, under_review: 1, resolved: 2, dismissed: 3) }
  end

  describe 'scopes' do
    let!(:pending_report) { create(:report, status: :pending) }
    let!(:resolved_report) { create(:report, status: :resolved) }

    it 'returns unresolved reports' do
      expect(Report.unresolved).to include(pending_report)
      expect(Report.unresolved).not_to include(resolved_report)
    end

    it 'returns recent reports' do
      expect(Report.recent.first).to eq(resolved_report)
    end
  end

  describe '#resolve!' do
    let(:moderator) { create(:user, role: 'moderator') }

    it 'resolves the report' do
      report.resolve!(moderator, 'resolved')
      
      expect(report.status).to eq('resolved')
      expect(report.resolved_by).to eq(moderator)
      expect(report.resolved_at).to be_present
    end
  end
end
