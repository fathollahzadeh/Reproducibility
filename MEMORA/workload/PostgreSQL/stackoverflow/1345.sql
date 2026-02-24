WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserMetrics AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.CommentCount, 0) AS TotalComments,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        COALESCE(PS.AcceptedAnswers, 0) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.TotalComments,
    U.TotalViews,
    U.AverageScore,
    U.AcceptedAnswers,
    CASE 
        WHEN U.BadgeCount >= 10 THEN 'Star Contributor'
        WHEN U.TotalComments > 100 THEN 'Comment King'
        WHEN U.TotalViews > 1000 THEN 'View Magnet'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    UserMetrics U
WHERE 
    U.TotalComments > 0
ORDER BY 
    U.TotalViews DESC
LIMIT 10;