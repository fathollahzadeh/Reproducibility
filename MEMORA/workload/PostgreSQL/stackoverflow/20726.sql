
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),

BadgedUsers AS (
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

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.Upvotes,
    up.Downvotes,
    bu.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    UserReputation up
LEFT JOIN 
    BadgedUsers bu ON up.UserId = bu.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.UserPostRank = 1 
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    up.Reputation > 1000
    AND (bu.BadgeCount IS NULL OR bu.BadgeCount > 2) 
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate ASC;
