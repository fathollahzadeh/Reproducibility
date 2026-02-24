WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        CreationDate,
        Row_Number() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS RecentPostRank
    FROM 
        Posts
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBounty,
    us.TotalQuestions,
    us.TotalAnswers,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    CASE 
        WHEN us.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    CASE 
        WHEN us.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Veteran'
        ELSE 'Newcomer'
    END AS UserStatus
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.RecentPostRank = 1
WHERE 
    us.Reputation > 100
ORDER BY 
    us.Reputation DESC, us.DisplayName ASC
LIMIT 10;