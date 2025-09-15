FactoryBot.define do
  factory :appeal do
    association :user
    association :moderation_action
    reason { "I believe this action was taken in error. I was not violating any community guidelines." }
    status { :pending }
    reviewed_by { nil }
    reviewed_at { nil }
  end
end
