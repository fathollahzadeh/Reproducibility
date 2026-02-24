WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), HighlyActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalBounties,
        Rank
    FROM 
        UserStats
    WHERE 
        TotalPosts > 10
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ha.TotalPosts,
    ha.TotalAnswers,
    ha.TotalBounties,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    HighlyActiveUsers ha
JOIN 
    RecentPosts rp ON ha.UserId = rp.OwnerUserId
LEFT JOIN 
    Users u ON ha.UserId = u.Id
WHERE 
    ha.Rank <= 50
    AND rp.RecentRank = 1
ORDER BY 
    ha.TotalBounties DESC, 
    u.Reputation DESC;