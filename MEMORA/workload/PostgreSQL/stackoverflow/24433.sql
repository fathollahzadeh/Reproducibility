WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(p.Tags, ''), 'Unlabeled') AS ProcessedTags
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ub.BadgeCount,
        ub.BadgeNames,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        CASE 
            WHEN rp.Score > 50 THEN 'High Scorer'
            WHEN rp.Score BETWEEN 10 AND 50 THEN 'Medium Scorer'
            ELSE 'Low Scorer'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank = 1
), 
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS ClosedByUser
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)

SELECT 
    ps.Title,
    ps.Score,
    ps.BadgeCount,
    ps.BadgeNames,
    ps.CommentCount,
    ps.ScoreCategory,
    cp.CloseDate,
    u.DisplayName AS ClosedByUserName
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
LEFT JOIN 
    Users u ON cp.ClosedByUser = u.Id
WHERE 
    ps.BadgeCount > 0
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC
LIMIT 10;