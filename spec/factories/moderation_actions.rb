FactoryBot.define do
  factory :moderation_action do
    association :user
    association :moderator, factory: :user
    action_type { "warning" }
    reason { "Violation of community guidelines" }
    association :target, factory: :user
    expires_at { nil }
  end
end
