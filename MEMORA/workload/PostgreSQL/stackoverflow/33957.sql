
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pv.Upvotes,
    pv.Downvotes,
    COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
    rp.UserRank
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostVoteCounts pv ON rp.PostId = pv.PostId
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
WHERE 
    rp.UserRank <= 5  
ORDER BY 
    u.DisplayName, 
    rp.Score DESC;
