WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
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
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation >= 100
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PopularPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ur.Reputation,
        pc.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.rn = 1 AND
        (ur.TotalBounty > 0 OR ur.Reputation > 200)
)
SELECT 
    pp.Title,
    pp.Score,
    pp.CreationDate,
    pp.Reputation,
    COALESCE(pp.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN pp.Score >= 100 THEN 'Highly Active'
        WHEN pp.Score BETWEEN 50 AND 99 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    PopularPosts pp
ORDER BY 
    pp.Score DESC,
    pp.CreationDate DESC
LIMIT 10;
