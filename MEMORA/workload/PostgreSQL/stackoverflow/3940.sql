WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN P.Id END) AS ClosedPosts
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.PostCount,
        PS.TotalScore,
        PS.TotalViews,
        PS.ClosedPosts
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(UP.TotalScore, 0) AS TotalScore,
    COALESCE(UP.ClosedPosts, 0) AS ClosedPosts,
    U.Rank,
    CASE 
        WHEN UP.PostCount IS NULL THEN 'No Posts'
        WHEN UP.TotalScore = 0 THEN 'Low Engagement'
        ELSE 'Active Contributor'
    END AS ContributionStatus,
    (SELECT COUNT(DISTINCT C.Id)
     FROM Comments C
     WHERE C.UserId = U.UserId) AS CommentCount
FROM UserReputation U
LEFT JOIN UserPostStats UP ON U.UserId = UP.UserId
WHERE U.Rank <= 10
ORDER BY U.Rank;