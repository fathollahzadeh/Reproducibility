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
HighScorePosts AS (
    SELECT 
        P.OwnerUserId, 
        P.Title, 
        COUNT(C.Id) AS CommentCount,
        P.Score
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0  
    GROUP BY 
        P.OwnerUserId, P.Title, P.Score
),
UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(HSP.Score), 0) AS TotalPostScore,
        COALESCE(SUM(HP.BadgeCount), 0) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        HighScorePosts HSP ON U.Id = HSP.OwnerUserId
    LEFT JOIN 
        UserBadges HP ON U.Id = HP.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UPM.UserId,
    UPM.DisplayName,
    UPM.TotalPostScore,
    UPM.TotalBadges,
    UPM.TotalPosts,
    UPM.TotalComments,
    (UPM.TotalPosts * 100 / NULLIF(UPM.TotalBadges, 0)) AS PostsPerBadge
FROM 
    UserPostMetrics UPM
ORDER BY 
    UPM.TotalPostScore DESC, 
    UPM.TotalBadges DESC;