WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
)
SELECT 
    up.UserId,
    up.Reputation,
    rp.Title,
    rp.CommentCount,
    rp.AvgBounty,
    CASE 
        WHEN rp.OwnerPostRank = 1 THEN 'Most Recent Post'
        ELSE 'Other Posts'
    END AS PostStatus
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = up.UserId 
        AND p.CreationDate < rp.CreationDate
        AND p.ViewCount < 100
    )
ORDER BY 
    up.Reputation DESC, 
    rp.CommentCount DESC
LIMIT 100;