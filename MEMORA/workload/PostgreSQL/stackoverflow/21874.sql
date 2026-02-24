WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ub.BadgeCount,
    ub.HighestBadge,
    phc.HistoryChangeCount,
    CASE 
        WHEN rp.RankByScore <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN rp.Score > 50 THEN 'High Engagement'
        WHEN rp.Score BETWEEN 20 AND 50 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CASE 
        WHEN phc.HistoryChangeCount > 10 THEN 'Frequent Changes'
        WHEN phc.HistoryChangeCount IS NULL THEN 'No Change History'
        ELSE 'Some Changes'
    END AS ChangeActivity
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId
LEFT JOIN 
    PostHistoryCount phc ON rp.PostId = phc.PostId
WHERE 
    ub.BadgeCount > 5
    OR phc.HistoryChangeCount IS NOT NULL
ORDER BY 
    rp.Score DESC;