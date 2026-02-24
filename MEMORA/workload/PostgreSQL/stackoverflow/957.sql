
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalBadges,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation IS NOT NULL
        AND ur.TotalBadges > 2 
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    ur.TotalBadges AS OwnerBadges,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = p.PostId) AS CommentCount,
    (SELECT STRING_AGG(DISTINCT lt.Name, ', ') 
     FROM PostLinks pl 
     JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id 
     WHERE pl.PostId = p.PostId) AS RelatedPosts,
    t.UserRank
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    p.Rank = 1 
ORDER BY 
    t.UserRank, p.ViewCount DESC;
