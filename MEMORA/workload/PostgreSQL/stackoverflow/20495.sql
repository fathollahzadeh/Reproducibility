WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    pc.AllComments,
    ur.AverageBounty,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE 'Previous Post'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
JOIN 
    UserReputation ur ON up.Id = ur.UserId
WHERE 
    ur.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;