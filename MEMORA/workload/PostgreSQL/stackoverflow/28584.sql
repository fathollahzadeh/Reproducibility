WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN P.Score < 0 THEN P.Score ELSE 0 END) AS NegativeScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT L.RelatedPostId) AS LinkedPostCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks L ON P.Id = L.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
),

AggregatedMetrics AS (
    SELECT 
        UM.UserId,
        UM.DisplayName,
        UM.Reputation,
        UM.PostCount,
        UM.PositiveScore,
        UM.NegativeScore,
        UM.BadgeCount,
        COALESCE(SUM(PS.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(PS.Score), 0) AS TotalScore,
        COALESCE(SUM(PS.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(PS.LinkedPostCount), 0) AS TotalLinkedPosts
    FROM UserMetrics UM
    LEFT JOIN PostStatistics PS ON UM.UserId = PS.PostId
    GROUP BY UM.UserId, UM.DisplayName, UM.Reputation, UM.PostCount, UM.PositiveScore, UM.NegativeScore, UM.BadgeCount
)

SELECT 
    AM.UserId,
    AM.DisplayName,
    AM.Reputation,
    AM.PostCount,
    AM.PositiveScore,
    AM.NegativeScore,
    AM.BadgeCount,
    AM.TotalViews,
    AM.TotalScore,
    AM.TotalComments,
    AM.TotalLinkedPosts
FROM AggregatedMetrics AM
WHERE AM.Reputation > 1000
ORDER BY AM.Reputation DESC, AM.PostCount DESC, AM.TotalViews DESC;
