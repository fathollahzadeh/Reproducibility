WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
    AND 
        u.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY rp.CommentCount DESC, rp.TotalBounty DESC) AS PostRank
    FROM 
        RecentPosts rp
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.TotalBounty
FROM 
    UserReputation ur
JOIN 
    Posts p ON ur.UserId = p.OwnerUserId
JOIN 
    TopPosts tp ON p.Id = tp.PostId
WHERE 
    tp.PostRank <= 10
AND 
    (ur.Reputation > 2000 OR tp.TotalBounty > 0)
ORDER BY 
    ur.Reputation DESC, tp.CommentCount DESC;