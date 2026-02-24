
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
CommentsSummary AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    GROUP BY 
        PostId
),
BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeLevel
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.AvgCommentScore, 0) AS AverageCommentScore,
    COALESCE(bs.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN bs.HighestBadgeLevel = 1 THEN 'Gold'
        WHEN bs.HighestBadgeLevel = 2 THEN 'Silver'
        WHEN bs.HighestBadgeLevel = 3 THEN 'Bronze'
        ELSE 'No Badges'
    END AS UserHighestBadgeLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentsSummary cs ON rp.PostId = cs.PostId
LEFT JOIN 
    BadgesSummary bs ON rp.OwnerUserId = bs.UserId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
