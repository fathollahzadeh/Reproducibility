
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    COALESCE(pcc.CommentCount, 0) AS CommentCount,
    rp.TotalBounty,
    CASE 
        WHEN rp.TotalBounty > 100 THEN 'High Bounty'
        WHEN rp.TotalBounty BETWEEN 50 AND 100 THEN 'Medium Bounty'
        ELSE 'Low Bounty'
    END AS BountyCategory
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostCommentCounts pcc ON rp.PostId = pcc.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
