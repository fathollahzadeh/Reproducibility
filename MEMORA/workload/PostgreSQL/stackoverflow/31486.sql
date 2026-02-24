WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerName,
    ps.CommentCount,
    ps.VoteCount,
    ps.AverageBounty,
    COALESCE(tb.BadgeCount, 0) AS GoldBadgeCount,
    CASE
        WHEN rp.Score >= 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE
        WHEN ps.VoteCount > 10 THEN 'High Engagement'
        WHEN ps.VoteCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    RecentPosts rp
LEFT JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
LEFT JOIN 
    TopBadges tb ON rp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = tb.UserId) 
WHERE 
    rp.rn <= 5  
ORDER BY 
    rp.CreationDate DESC;