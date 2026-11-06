class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

         validates :name, presence: true, unless: :guest?

         has_many :tdee_profiles, dependent: :destroy
         has_many :menus, dependent: :destroy
         has_many :user_allergens, dependent: :destroy
         has_many :allergens, through: :user_allergens, source: :allergen_master
         has_many :favorites, dependent: :destroy
         has_many :weight_records, dependent: :destroy

         def send_devise_notification(notification, *args)
            devise_mailer.send(notification, self, *args).deliver_later
         end
end
