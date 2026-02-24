WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
UserPosts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(ViewCount) AS AvgViewCount
    FROM Posts
    GROUP BY OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UP.PostCount, 0) AS TotalPosts,
        COALESCE(UP.QuestionsCount, 0) AS TotalQuestions,
        COALESCE(UP.AnswersCount, 0) AS TotalAnswers,
        COALESCE(UP.AvgViewCount, 0) AS AvgViewCount,
        DENSE_RANK() OVER (ORDER BY COALESCE(UP.PostCount, 0) DESC) AS PostRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UserPosts UP ON U.Id = UP.OwnerUserId
    WHERE U.Reputation > 0
),
TopActiveUsers AS (
    SELECT UserId, DisplayName, TotalBadges, TotalPosts, TotalQuestions, TotalAnswers, AvgViewCount
    FROM ActiveUsers
    WHERE PostRank <= 10
)
SELECT 
    A.DisplayName,
    A.TotalBadges,
    A.TotalPosts,
    A.TotalQuestions,
    A.TotalAnswers,
    A.AvgViewCount,
    CASE 
        WHEN A.TotalBadges = 0 THEN 'No Badges'
        WHEN A.TotalBadges > 5 THEN 'Very Active'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM TopActiveUsers A
ORDER BY A.TotalPosts DESC, A.TotalBadges DESC;
