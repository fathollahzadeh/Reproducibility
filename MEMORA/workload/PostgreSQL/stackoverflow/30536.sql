
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ra.CommentCount,
    ra.TotalBounty,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount
FROM 
    UserReputation ur
LEFT JOIN 
    RecentActivity ra ON ur.UserId = ra.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId AND rp.UserPostRank = 1
WHERE 
    ur.Reputation > 1000
    AND (ra.CommentCount > 5 OR ra.TotalBounty > 0)
ORDER BY 
    ur.Reputation DESC, ra.TotalBounty DESC;
