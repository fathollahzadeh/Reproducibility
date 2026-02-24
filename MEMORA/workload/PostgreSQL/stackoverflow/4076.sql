
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' 
        AND p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.TotalBounty,
    rp.Title,
    rp.ViewCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount
FROM 
    UserReputation ur
JOIN 
    Users u ON ur.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
GROUP BY 
    u.DisplayName, ur.Reputation, ur.PostCount, ur.TotalBounty, rp.Title, rp.ViewCount
ORDER BY 
    ur.Reputation DESC,
    ur.TotalBounty DESC
LIMIT 10;
