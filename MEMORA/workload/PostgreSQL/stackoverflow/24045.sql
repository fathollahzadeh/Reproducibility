
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN P.Score >= 0 THEN 1 END) AS NonNegativePosts
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.QuestionCount, 0) AS TotalQuestions,
        COALESCE(PS.AnswerCount, 0) AS TotalAnswers,
        COALESCE(PS.NonNegativePosts, 0) AS TotalNonNegativePosts,
        RANK() OVER (ORDER BY COALESCE(UB.BadgeCount, 0) DESC, COALESCE(PS.QuestionCount, 0) DESC) AS Ranking
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalBadges,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.TotalNonNegativePosts,
        UA.Ranking
    FROM UserActivity UA
    WHERE UA.TotalBadges > 0 OR UA.TotalQuestions > 0
    ORDER BY UA.Ranking
    LIMIT 10
)
SELECT 
    TU.DisplayName,
    TU.TotalBadges,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalNonNegativePosts,
    CASE 
        WHEN TU.TotalQuestions = 0 THEN NULL
        ELSE ROUND((TU.TotalAnswers * 1.0 / NULLIF(TU.TotalQuestions, 0)) * 100, 2)
    END AS AnswerRate,
    CASE 
        WHEN TU.TotalBadges = 0 THEN 'No Badges'
        ELSE CASE 
            WHEN TU.TotalBadges >= 5 THEN 'Active Contributor'
            ELSE 'Emerging Contributor'
        END
    END AS ContributorStatus
FROM TopUsers TU
WHERE TU.TotalNonNegativePosts > 5
AND TU.TotalBadges + TU.TotalQuestions > (SELECT AVG(TotalBadges + TotalQuestions) FROM UserActivity)
ORDER BY TU.TotalBadges DESC, TU.TotalQuestions DESC;
