FactoryBot.define do
  factory :report do
    association :user
    association :reportable, factory: :post
    reason { "spam" }
    description { "This content appears to be spam and violates community guidelines." }
    status { :pending }
    resolved_by { nil }
    resolved_at { nil }
  end
end
