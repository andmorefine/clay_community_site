FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    skill_level { %w[beginner intermediate advanced expert].sample }
    bio         { Faker::Lorem.sentence(word_count: 10) }
    
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

    after(:build) do |user|
      user.profile_image.attach(
        io:          File.open(Rails.root.join("spec/fixtures/files/sample.jpg")),
        filename:    "sample.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
