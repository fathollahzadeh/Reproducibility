
WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostNum
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
AggregatedPostData AS (
    SELECT 
        UR.DisplayName,
        COUNT(RP.PostId) AS RecentPostCount,
        SUM(RP.ViewCount) AS TotalViews,
        SUM(RP.Score) AS TotalScore
    FROM 
        UserRankings UR
    JOIN 
        RecentPosts RP ON UR.UserId = RP.OwnerUserId
    GROUP BY 
        UR.DisplayName
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    APD.RecentPostCount,
    APD.TotalViews,
    APD.TotalScore,
    CASE 
        WHEN APD.RecentPostCount IS NULL THEN 'No Recent Posts'
        ELSE 'Active Contributor'
    END AS ContributionStatus,
    COALESCE(REPLACE(CAST(NULLIF(UR.GoldBadges, 0) AS VARCHAR), '0', 'No Gold Badges'), 'Gold badges: ' || UR.GoldBadges) AS GoldBadges,
    COALESCE(REPLACE(CAST(NULLIF(UR.SilverBadges, 0) AS VARCHAR), '0', 'No Silver Badges'), 'Silver badges: ' || UR.SilverBadges) AS SilverBadges,
    COALESCE(REPLACE(CAST(NULLIF(UR.BronzeBadges, 0) AS VARCHAR), '0', 'No Bronze Badges'), 'Bronze badges: ' || UR.BronzeBadges) AS BronzeBadges
FROM 
    UserRankings UR
LEFT JOIN 
    AggregatedPostData APD ON UR.DisplayName = APD.DisplayName
ORDER BY 
    UR.Reputation DESC, 
    APD.RecentPostCount DESC NULLS LAST;
