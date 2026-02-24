
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.CreationDate), DATE '1970-01-01') AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.CommentCount,
    ps.LastVoteDate,
    CASE 
        WHEN ps.LastVoteDate IS NULL THEN 'No Votes'
        WHEN ps.LastVoteDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS VoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts pp WHERE pp.Id = rp.PostId)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON rp.PostId = ps.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    ub.BadgeCount DESC;
