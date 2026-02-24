WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalScore,
        TotalPosts,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewsRank
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    RU.DisplayName,
    RU.TotalPosts,
    RU.TotalViews,
    RU.TotalScore,
    UB.BadgeNames,
    UB.BadgeCount,
    CASE 
        WHEN RU.ScoreRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    RankedUsers RU
LEFT JOIN 
    UserBadges UB ON RU.UserId = UB.UserId
WHERE 
    (UB.BadgeCount IS NULL OR UB.BadgeCount > 0)
    AND RU.TotalPosts > 5
ORDER BY 
    RU.TotalScore DESC, RU.TotalViews DESC
LIMIT 20;