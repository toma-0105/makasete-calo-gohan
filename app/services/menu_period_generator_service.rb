class MenuPeriodGeneratorService
  # 生成できる日数の下限・上限
  MIN_GENERATION_DAYS = 1
  MAX_GENERATION_DAYS = 7

  # 生成結果
  # menus: 今回新しく生成した献立 / skipped_menus: すでに献立があったためスキップした既存の献立
  Result = Struct.new(:menus, :skipped_menus) do
    # 対象期間の献立すべて（日付順）。結果画面にまとめて表示するために使う
    def all_menus
      (menus + skipped_menus).sort_by(&:date)
    end
  end

  def initialize(user, tdee_profile, days:)
    @user = user
    @tdee_profile = tdee_profile
    @days = days
  end

  # 今日から指定日数分のうち、まだ献立がない日だけ生成・保存する
  def generate!
    unless (MIN_GENERATION_DAYS..MAX_GENERATION_DAYS).cover?(@days)
      raise ArgumentError, "daysは#{MIN_GENERATION_DAYS}〜#{MAX_GENERATION_DAYS}の範囲で指定してください"
    end

    generate_missing_menus
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # 生成している間に別のリクエストが同じ日付の献立を先に作った場合は、その日が既存扱いになるようにやり直す
    # やり直すのは1回だけ。2回目も失敗したらそのまま例外にして、本当のエラーを握りつぶさない
    generate_missing_menus
  end

  private

  # 献立がない日を調べて生成する（スキップ判定からやり直せるよう切り出している）
  def generate_missing_menus
    dates = Array.new(@days) { |i| Date.current + i.days }
    existing_menus = @user.menus.includes(:meals).where(date: dates).order(:date)
    new_dates = dates - existing_menus.map(&:date)

    Result.new(generate_menus!(new_dates, existing_menus), existing_menus.to_a)
  end

  # 指定した日付の献立を生成して保存する
  def generate_menus!(dates, existing_menus)
    # すでにある日の料理も使用済みとして扱い、前後の日で同じ料理が続かないようにする
    used_meal_master_ids = existing_menus.flat_map { |menu| menu.meals.map(&:meal_master_id) }

    # 全日分を1つのトランザクションにまとめ、途中で失敗しても一部の日だけ保存された状態にならないようにする
    ApplicationRecord.transaction do
      dates.map do |date|
        menu_hash = MenuCalorieRangeSelectorService.new(
          @tdee_profile,
          additional_excluded_meal_master_ids: used_meal_master_ids.dup
        ).generate

        used_meal_master_ids.concat(menu_hash.values.flatten.map { |selected| selected.meal_master.id })

        MenuSaveService.new(@user, menu_hash, date: date).save!
      end
    end
  end
end
