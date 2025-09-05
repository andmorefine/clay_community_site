FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag#{n}" }
    
    trait :clay do
      name { "clay" }
    end
    
    trait :pottery do
      name { "pottery" }
    end
    
    trait :ceramic do
      name { "ceramic" }
    end
    
    trait :sculpture do
      name { "sculpture" }
    end
    
    trait :handmade do
      name { "handmade" }
    end
  end
end