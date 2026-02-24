
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        CreationDate,
        Tags,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS RecentPostRank
    FROM 
        Posts
    WHERE 
        CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        u.DisplayName,
        COALESCE(b.Count, 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounties,
    us.TotalPosts,
    us.TotalComments,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.BadgeCount AS UserBadgeCount,
    CASE 
        WHEN us.Reputation >= 1000 THEN 'Highly Reputable'
        ELSE 'Newcomer'
    END AS UserStatus
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId AND tp.PostRank = 1
WHERE 
    us.UserRank <= 10
ORDER BY 
    us.Reputation DESC;
