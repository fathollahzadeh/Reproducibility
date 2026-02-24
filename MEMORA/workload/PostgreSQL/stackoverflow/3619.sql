WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.TotalPosts,
        P.Questions,
        P.Answers,
        P.TotalViews,
        P.LatestPostDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM UserReputation U
    LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
)

SELECT 
    C.UserId,
    C.Reputation,
    C.BadgeCount,
    C.GoldBadges,
    C.SilverBadges,
    C.BronzeBadges,
    COALESCE(C.TotalPosts, 0) AS TotalPosts,
    COALESCE(C.Questions, 0) AS Questions,
    COALESCE(C.Answers, 0) AS Answers,
    COALESCE(C.TotalViews, 0) AS TotalViews,
    C.LatestPostDate,
    CASE 
        WHEN C.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN C.ReputationRank <= 50 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM CombinedStats C
LEFT JOIN Votes V ON C.UserId = V.UserId
WHERE C.Reputation > 1000
ORDER BY C.Reputation DESC;


