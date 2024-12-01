FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2024-11-30 18:57:46" }
  end
end
