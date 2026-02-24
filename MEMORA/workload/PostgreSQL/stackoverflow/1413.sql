
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class
         FROM Badges 
         GROUP BY UserId) b ON u.Id = b.UserId
)
SELECT 
    up.RecentPostRank,
    up.Title,
    up.CommentCount,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeClass
FROM 
    RecentPosts up
JOIN 
    UserReputation ur ON up.OwnerUserId = ur.UserId
WHERE 
    ur.Reputation > 1000
    AND (ur.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years' OR ur.BadgeClass = 1)
    AND EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = up.PostId 
        AND v.VoteTypeId IN (2, 3) 
        GROUP BY v.PostId
        HAVING COUNT(v.VoteTypeId) > 5
    )
ORDER BY 
    up.CommentCount DESC, 
    ur.Reputation ASC
LIMIT 10;
