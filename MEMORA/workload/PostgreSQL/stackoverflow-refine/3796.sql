WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
) 
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ub.UserId AS BadgeUserId,
    ub.BadgeCount,
    CASE 
        WHEN ub.GoldBadge = 1 THEN 'Gold'
        WHEN ub.SilverBadge = 1 THEN 'Silver'
        WHEN ub.BronzeBadge = 1 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostID AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.Score >= u.Reputation
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC;