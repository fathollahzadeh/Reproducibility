WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.PostCount,
    us.TotalBounties,
    us.AvgViews,
    COALESCE(pwc.CommentCount, 0) AS TotalComments,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    u.Reputation > 1000 
    AND (us.TotalBounties IS NULL OR us.TotalBounties > 0) 
    AND rp.rn = 1
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;