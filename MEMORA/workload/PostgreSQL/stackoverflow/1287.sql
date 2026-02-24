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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.CreationDate) AS MostRecentPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalScore, 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        UserBadges ub ON U.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON U.Id = ps.OwnerUserId
    WHERE 
        U.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    U.DisplayName,
    AU.Reputation,
    AU.BadgeCount,
    AU.PostCount,
    AU.TotalScore,
    CASE 
        WHEN AU.TotalScore > 100 THEN 'High Performer'
        WHEN AU.TotalScore BETWEEN 50 AND 100 THEN 'Moderate Performer'
        ELSE 'Needs Improvement'
    END AS PerformanceCategory
FROM 
    ActiveUsers AU
JOIN 
    Users U ON AU.Id = U.Id
LEFT JOIN 
    Votes V ON U.Id = V.UserId 
GROUP BY 
    U.DisplayName, AU.Reputation, AU.BadgeCount, AU.PostCount, AU.TotalScore
ORDER BY 
    AU.TotalScore DESC,
    U.DisplayName ASC;