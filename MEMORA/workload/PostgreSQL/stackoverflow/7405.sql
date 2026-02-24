
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
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
        COUNT(C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.CommentCount,
        PS.TotalViews,
        PS.AverageScore
    FROM 
        Users U
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UE.UserId,
    UE.DisplayName,
    UE.BadgeCount,
    COALESCE(UE.CommentCount, 0) AS CommentCount,
    COALESCE(UE.TotalViews, 0) AS TotalViews,
    COALESCE(UE.AverageScore, 0.0) AS AverageScore,
    RANK() OVER (ORDER BY UE.TotalViews DESC) AS ViewRank,
    RANK() OVER (ORDER BY UE.BadgeCount DESC) AS BadgeRank
FROM 
    UserEngagement UE
WHERE 
    UE.BadgeCount > 0
ORDER BY 
    UE.TotalViews DESC, UE.BadgeCount DESC;
