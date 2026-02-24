
WITH RECURSIVE RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days' 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalBounty,
        TotalComments,
        LastPostDate,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalBounty DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    t.TotalPosts,
    t.TotalBounty,
    t.TotalComments,
    t.LastPostDate,
    tp.Title AS RecentPostTitle,
    tp.CreationDate AS RecentPostDate
FROM 
    TopUsers t
JOIN 
    Users u ON u.Id = t.UserId
LEFT JOIN 
    RecentPosts tp ON tp.OwnerUserId = t.UserId AND tp.rn = 1
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;
