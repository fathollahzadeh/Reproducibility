
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
HighScoredPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rb.UserId,
        rb.BadgeCount,
        rb.GoldCount,
        rb.SilverCount,
        rb.BronzeCount,
        rp.Score
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges rb ON rp.OwnerUserId = rb.UserId
    WHERE 
        rp.Score > 100 AND 
        rb.BadgeCount IS NOT NULL
),
CommentedPosts AS (
    SELECT 
        PostId,
        AVG(Score) AS AverageScore
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.BadgeCount,
    COALESCE(cp.AverageScore, 0) AS AverageCommentScore,
    (CASE 
         WHEN hsp.GoldCount > 0 THEN 'Gold'
         WHEN hsp.SilverCount > 0 THEN 'Silver'
         WHEN hsp.BronzeCount > 0 THEN 'Bronze'
         ELSE 'No Badge'
     END) AS HighestBadge
FROM 
    HighScoredPosts hsp
LEFT JOIN 
    CommentedPosts cp ON hsp.PostId = cp.PostId
ORDER BY 
    hsp.Score DESC,
    hsp.BadgeCount DESC
LIMIT 10;
