WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(c.UserDisplayName, 'Anonymous') AS CommenterName,
        c.CreationDate AS CommentDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, c.UserDisplayName, c.CreationDate
)
SELECT 
    rp.Title,
    u.DisplayName,
    u.Reputation,
    COALESCE(bc.GoldCount, 0) AS GoldBadges,
    COALESCE(bc.SilverCount, 0) AS SilverBadges,
    COALESCE(bc.BronzeCount, 0) AS BronzeBadges,
    ap.CommentCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS TotalUpvotes,
    CASE 
        WHEN ap.CommentCount > 0 THEN 'Has comments'
        ELSE 'No comments'
    END AS CommentStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    BadgeCounts bc ON u.Id = bc.UserId
LEFT JOIN 
    ActivePosts ap ON rp.Id = ap.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC;