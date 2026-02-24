
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
),
PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.ViewCount,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN rp.Upvotes + rp.Downvotes > 0 
            THEN (CAST(rp.Upvotes AS DECIMAL) / (rp.Upvotes + rp.Downvotes)) * 100 
            ELSE NULL 
        END AS UpvotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvotePercentage,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    PostStats ps
JOIN 
    UserReputation ur ON ps.OwnerUserId = ur.UserId
WHERE 
    (ur.Reputation >= 1000 OR ur.BadgeCount > 5)
ORDER BY 
    ps.ViewCount DESC
LIMIT 10;
