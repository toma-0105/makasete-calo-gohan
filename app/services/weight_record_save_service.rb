# 体重記録の保存と、それに伴うTDEEプロフィールの再計算をまとめて行う
class WeightRecordSaveService
  def initialize(user, weight:, recorded_on:)
    @user = user
    @weight = weight
    @recorded_on = recorded_on
  end

  def save!
    weight_record = WeightRecordUpsertService.new(@user, weight: @weight, recorded_on: @recorded_on).call
    sync_tdee_profile!
    weight_record
  end

  private

  def sync_tdee_profile!
    last_profile = @user.tdee_profiles.last
  return unless last_profile

  new_profile = @user.tdee_profiles.create!(
    last_profile.attributes.slice("height", "age", "gender", "activity_level")
                            .merge(weight: @weight)
  )
  TdeeCalculatorService.new(new_profile).calculate
  end
end
