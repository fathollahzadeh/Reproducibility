WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS BadgeCount,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY SUM(P.ViewCount) DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.LastAccessDate,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.Questions, 0) AS TotalQuestions,
    COALESCE(PS.Answers, 0) AS TotalAnswers,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    CASE 
        WHEN U.Location IS NULL THEN 'Location Not Specified'
        ELSE U.Location 
    END AS UserLocation
FROM Users U
LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
WHERE 
    U.Reputation > 100 AND 
    (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL)
ORDER BY 
    U.Reputation DESC, 
    PS.TotalViews DESC 
LIMIT 10;