FactoryBot.define do
  factory :comment do
    association :user
    association :post
    content { "This is a great piece! I love the texture and the color choices. Thanks for sharing your technique." }
    
    trait :short do
      content { "Nice work!" }
    end
    
    trait :long do
      content { "This is an absolutely stunning piece of pottery! The attention to detail is remarkable, and I can see the skill and patience that went into creating this. The glazing technique you used creates such a beautiful finish. I'm particularly impressed by the way you handled the rim - it's perfectly smooth and even. As someone who's been working with clay for several years, I can appreciate the technical skill required to achieve this level of quality. Thank you for sharing your process and inspiring others in the community!" }
    end
    
    trait :question do
      content { "What type of clay did you use for this piece? And what was your firing temperature?" }
    end
  end
end