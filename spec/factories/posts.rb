FactoryBot.define do
  factory :post do
    association :user
    sequence(:title) { |n| "Clay Creation #{n}" }
    description { "This is a beautiful clay piece I created using traditional techniques. The process involved careful preparation of the clay, shaping, and firing in a kiln." }
    post_type { "regular" }
    published { true }
    
    # Note: In a real test environment, you would attach actual image files
    # For now, we'll skip the images validation in tests or mock it
    
    trait :tutorial do
      post_type { "tutorial" }
      difficulty_level { "beginner" }
      title { "How to Make a Simple Clay Bowl" }
      description { "Step-by-step tutorial on creating your first clay bowl. Perfect for beginners who want to learn the basics of pottery." }
    end
    
    trait :unpublished do
      published { false }
    end
    
    trait :advanced_tutorial do
      post_type { "tutorial" }
      difficulty_level { "advanced" }
      title { "Advanced Glazing Techniques" }
      description { "Learn advanced glazing methods to create stunning finishes on your pottery pieces." }
    end
    
    trait :with_long_description do
      description { "This is a very detailed description of my clay creation process. " * 20 }
    end
  end
end