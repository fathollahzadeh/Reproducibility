WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        ur.TotalBadges,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostCount > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    ua.UserId,
    ua.Reputation,
    rp.CommentCount,
    rp.TotalBounty,
    ua.PostCount,
    ua.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.TotalBounty > 0
   OR EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId AND c.UserId IS NOT NULL)
ORDER BY 
    ua.Reputation DESC, rp.CreationDate DESC
LIMIT 100;