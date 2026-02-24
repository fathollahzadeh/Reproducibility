WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.AcceptedAnswers,
    COALESCE(ra.TotalComments, 0) AS RecentComments,
    COALESCE(ra.TotalVotes, 0) AS RecentVotes,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate,
    rp.Score AS MostRecentPostScore,
    rp.ViewCount AS MostRecentPostViews
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentActivity ra ON u.Id = ra.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.TotalPosts DESC, us.Reputation DESC;