WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
TopBadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(b.Id) > 5
),
RecentVotes AS (
    SELECT 
        DISTINCT v.PostId,
        v.UserId,
        vn.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vn ON vn.Id = v.VoteTypeId
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        v.PostId, v.UserId, vn.Name
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    ur.DisplayName AS OwnerName,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    coalesce(tu.BadgeCount, 0) AS BadgeCount,
    coalesce(tu.GoldBadges, 0) AS GoldBadges,
    coalesce(tu.SilverBadges, 0) AS SilverBadges,
    coalesce(tu.BronzeBadges, 0) AS BronzeBadges,
    rp.CommentCount,
    rv.VoteType,
    rv.VoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users ur ON ur.Id = rp.OwnerUserId
LEFT JOIN 
    TopBadgedUsers tu ON tu.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentVotes rv ON rv.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
    AND rp.Score > 0
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;