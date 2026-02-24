
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostScoreStats AS (
    SELECT 
        P.OwnerUserId,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.PostId, 
        V.UserId,
        COUNT(*) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        V.PostId, V.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.AvgScore, 0) AS AveragePostScore,
    COALESCE(PS.TotalViews, 0) AS TotalPostViews,
    COALESCE(PS.PostCount, 0) AS TotalPosts,
    COALESCE(R.VoteCount, 0) AS RecentVoteCount
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN 
    PostScoreStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    (SELECT 
        PostId, 
        SUM(VoteCount) AS VoteCount 
    FROM 
        RecentVotes 
    GROUP BY 
        PostId) R ON R.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC;
