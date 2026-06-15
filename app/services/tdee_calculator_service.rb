class TdeeCalculatorService
    # 活動レベルの係数
    ACTIVITY_MULTIPLIERS = {
    sedentary:        1.2,
    lightly_active:   1.375,
    moderately_active: 1.55,
    very_active:      1.725,
    super_active:      1.9
}.freeze

    def initialize(tdee_profile)
        @profile = tdee_profile
    end

    def calculate
        bmr             = calculate_bmr
        tdee            = (bmr * activity_multiplier).round(2)
        target_calories = (tdee * 0.85).round(2)

        @profile.update!(
            tdee:            tdee,
            target_calories: target_calories
        )
    end

    private

    def calculate_bmr
        if @profile.male?
            88.362 +(13.397 * @profile.weight) +
                    (4.799 * @profile.height) -
                    (5.677 * @profile.age)
        else
            447.593 + (9.247 * @profile.weight) +
                    (3.098 * @profile.height) -
                    (4.330 * @profile.age)
        end
    end

    def activity_multiplier
        ACTIVITY_MULTIPLIERS[@profile.activity_level.to_sym]
    end
end
