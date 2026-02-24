WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.Questions, 0) AS TotalQuestions,
        COALESCE(PS.Answers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY COALESCE(PS.TotalViews, 0) DESC, 
                                  COALESCE(PS.TotalScore, 0) DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation > 0
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    Rank
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;