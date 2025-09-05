FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    bio { "I love working with clay and creating beautiful pottery pieces." }
    skill_level { "beginner" }
    
    trait :intermediate do
      skill_level { "intermediate" }
    end
    
    trait :advanced do
      skill_level { "advanced" }
    end
    
    trait :expert do
      skill_level { "expert" }
    end
    
    trait :with_bio do
      bio { "Passionate clay artist with #{skill_level} level skills. Love sharing techniques and learning from others." }
    end
  end
end