
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(*) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, B.Class
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '6 months' 
        AND P.Score > 0
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        C.PostId
),
Combined AS (
    SELECT 
        U.DisplayName AS UserName,
        P.Title AS PostTitle,
        COALESCE(RC.CommentCount, 0) AS RecentComments,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        PB.Class AS BadgeClass,
        PP.ViewRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        RecentComments RC ON P.Id = RC.PostId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PopularPosts PP ON P.Id = PP.PostId
    LEFT JOIN 
        (SELECT DISTINCT Class FROM UserBadges) PB ON U.Id = UB.UserId
    WHERE 
        U.Reputation > 100
)
SELECT 
    UserName,
    PostTitle,
    RecentComments,
    TotalBadges,
    COALESCE(BadgeClass, 0) AS BadgeClass,
    ViewRank
FROM 
    Combined
WHERE 
    ViewRank <= 10 OR TotalBadges > 5
ORDER BY 
    TotalBadges DESC,
    RecentComments DESC NULLS LAST;
