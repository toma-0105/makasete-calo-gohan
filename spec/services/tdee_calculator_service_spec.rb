require 'rails_helper'

RSpec.describe TdeeCalculatorService do
    describe '#calculate' do
        context '男性・30歳・170㎝・70kg・moderately_activeの場合' do
            let(:user) { create(:user) }
            let(:profile) do
                create(:tdee_profile,
                    user: user,
                    gender: :male,
                    age: 30,
                    height: 170,
                    weight: 70,
                    activity_level: :moderately_active
                )
            end

            before do
                TdeeCalculatorService.new(profile).calculate
                profile.reload
            end

            it 'TDEEが正しく計算される' do
                expect(profile.tdee).to be_within(1).of(2591.09)
            end
        end

        context '女性・25歳・160cm・55kg・lightly_activeの場合' do
            let(:user) { create(:user) }
            let(:profile) do
                create(:tdee_profile,
                    user: user,
                    gender: :female,
                    age: 25,
                    height: 160,
                    weight: 55,
                    activity_level: :lightly_active
                    )
            end

            before do
                TdeeCalculatorService.new(profile).calculate
                profile.reload
            end

            it 'TDEEが正しく計算される' do
                expect(profile.tdee).to be_within(1).of(1847.46)
            end

            it 'target_caloriesが正しく計算される' do
                expect(profile.target_calories).to be_within(1).of(1570.34)
            end
        end
    end
end
