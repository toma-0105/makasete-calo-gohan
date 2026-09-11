# 体重記録の作成・更新のみを行う（TDEE再計算には関与しない）
class WeightRecordUpsertService
  def initialize(user, weight:, recorded_on:)
    @user = user
    @weight = weight
    @recorded_on = recorded_on
  end

  def call
    weight_record = @user.weight_records.find_or_initialize_by(recorded_on: @recorded_on)
    weight_record.weight = @weight
    weight_record.save!
    weight_record
  end
end
