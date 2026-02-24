WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PopularityMetrics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
BadgeCounts AS (
    SELECT 
        userId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        userId
),
JoinMetrics AS (
    SELECT 
        pm.*,
        bc.BadgeCount
    FROM 
        PopularityMetrics pm
    LEFT JOIN 
        BadgeCounts bc ON pm.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bc.userId)
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerDisplayName,
    COALESCE(BadgeCount, 0) AS UserBadgeCount
FROM 
    JoinMetrics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 20;
