WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
MostActivePosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - interval '1 year' AND 
        P.PostTypeId = 1 
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UBadges.BadgeCount,
        MActive.PostCount,
        MActive.TotalViews,
        MActive.AvgScore,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    JOIN 
        UserBadges UBadges ON U.Id = UBadges.UserId
    JOIN 
        MostActivePosts MActive ON U.Id = MActive.OwnerUserId
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostCount,
    U.TotalViews,
    U.AvgScore,
    U.ReputationRank,
    COALESCE(COUNT(C.Id), 0) AS ContributionComments
FROM 
    TopUsers U
LEFT JOIN 
    Comments C ON U.Id = C.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.BadgeCount, U.PostCount, U.TotalViews, U.AvgScore, U.ReputationRank
ORDER BY 
    U.ReputationRank
LIMIT 10;