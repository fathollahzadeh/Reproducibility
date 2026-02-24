WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
CommentSummary AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(c.UserDisplayName, ', ') AS CommentAuthors,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.rn,
    ur.Reputation,
    ur.ReputationRank,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    cs.CommentAuthors,
    rp.TotalBounty
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ur.UserId)
LEFT JOIN 
    CommentSummary cs ON rp.PostId = cs.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, ur.Reputation DESC
LIMIT 100;