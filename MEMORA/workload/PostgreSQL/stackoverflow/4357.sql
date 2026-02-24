WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(U.Reputation) AS TotalReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        UBS.UserId,
        UBS.DisplayName,
        UBS.GoldBadges,
        UBS.SilverBadges,
        UBS.BronzeBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        UBS.TotalReputation,
        CASE 
            WHEN UBS.TotalReputation > 10000 THEN 'High'
            WHEN UBS.TotalReputation BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        UserBadgeStats UBS
    LEFT JOIN 
        PostStats PS ON UBS.UserId = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    U.TotalPosts,
    U.TotalViews,
    U.TotalReputation,
    U.ReputationLevel,
    RANK() OVER (ORDER BY U.TotalReputation DESC) AS ReputationRank
FROM 
    UserPerformance U
WHERE 
    U.TotalPosts > 5
ORDER BY 
    U.TotalReputation DESC, U.GoldBadges DESC, U.SilverBadges DESC;