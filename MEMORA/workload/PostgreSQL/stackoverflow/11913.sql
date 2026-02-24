WITH RecentUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        COUNT(DISTINCT c.Id) AS RecentCommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
)
SELECT 
    *
FROM 
    RecentUserStats
ORDER BY 
    Reputation DESC
LIMIT 100;