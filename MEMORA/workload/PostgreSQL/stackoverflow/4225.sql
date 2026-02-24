
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS TotalComments
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    us.DisplayName AS OwnerName,
    us.Reputation AS OwnerReputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pc.TotalComments, 0) AS TotalComments,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent'
        ELSE 'Earlier Post'
    END AS RecentClassification
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.CreationDate DESC
LIMIT 100
OFFSET 0;
