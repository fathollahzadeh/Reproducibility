WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS PostCount 
    FROM 
        Posts 
    GROUP BY 
        PostTypeId
),
UserActivity AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TotalPosts, 
        SUM(ViewCount) AS TotalViews, 
        SUM(Score) AS TotalScore 
    FROM 
        Posts 
    WHERE 
        OwnerUserId IS NOT NULL 
    GROUP BY 
        OwnerUserId
),
BadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalBadges 
    FROM 
        Badges 
    GROUP BY 
        UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(PC.PostCount, 0) AS TotalPostsByUser,
    COALESCE(UA.TotalViews, 0) AS TotalViewsByUser,
    COALESCE(UA.TotalScore, 0) AS TotalScoreByUser,
    COALESCE(BC.TotalBadges, 0) AS TotalBadgesByUser
FROM 
    Users U
LEFT JOIN 
    UserActivity UA ON U.Id = UA.OwnerUserId
LEFT JOIN 
    PostCounts PC ON U.Id = PC.PostTypeId
LEFT JOIN 
    BadgeCounts BC ON U.Id = BC.UserId
ORDER BY 
    TotalScoreByUser DESC, 
    TotalPostsByUser DESC;