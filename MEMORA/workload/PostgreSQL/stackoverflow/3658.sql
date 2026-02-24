WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, B.Class
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY V.UserId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.AverageScore,
    RV.TotalVotes,
    RV.UpVotes,
    RV.DownVotes
FROM UserBadges UB
FULL OUTER JOIN PostStats PS ON UB.UserId = PS.OwnerUserId
FULL OUTER JOIN RecentVotes RV ON UB.UserId = RV.UserId
WHERE COALESCE(PS.TotalPosts, 0) + COALESCE(RV.TotalVotes, 0) > 0
ORDER BY COALESCE(UB.BadgeCount, 0) DESC, PS.TotalPosts DESC NULLS LAST;