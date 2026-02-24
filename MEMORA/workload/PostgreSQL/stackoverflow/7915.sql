WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) as BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) as TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) as TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) as TotalAnswers,
        AVG(P.Score) as AvgScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(UB.BadgeCount, 0) as BadgeCount,
        COALESCE(PS.TotalPosts, 0) as TotalPosts,
        COALESCE(PS.TotalQuestions, 0) as TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) as TotalAnswers,
        COALESCE(PS.AvgScore, 0) as AvgScore
    FROM Users U
    LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.Id,
    UP.DisplayName,
    UP.Reputation,
    UP.LastAccessDate,
    UP.BadgeCount,
    UP.TotalPosts,
    UP.TotalQuestions,
    UP.TotalAnswers,
    UP.AvgScore
FROM UserPerformance UP
WHERE UP.Reputation > 1000
ORDER BY UP.AvgScore DESC, UP.TotalPosts DESC
LIMIT 10;