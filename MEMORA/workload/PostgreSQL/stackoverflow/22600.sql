
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(v.BountyAmount) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

RecentContributions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS ContributionRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
),

TotalAggregates AS (
    SELECT 
        ua.UserId,
        SUM(ua.TotalPosts) AS TotalPosts,
        SUM(ua.TotalComments) AS TotalComments,
        SUM(ua.Upvotes) AS Upvotes,
        SUM(ua.Downvotes) AS Downvotes,
        SUM(ua.TotalBounties) AS Bounties,
        COUNT(DISTINCT rc.PostId) AS RecentPostCount,
        MAX(rc.CreationDate) AS LastContributionDate
    FROM 
        UserActivity ua
    LEFT JOIN 
        RecentContributions rc ON ua.UserId = rc.PostId AND ua.TotalPosts > 0
    GROUP BY 
        ua.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.Upvotes,
    ua.Downvotes,
    ta.Bounties,
    ta.RecentPostCount,
    ta.LastContributionDate,
    CASE 
        WHEN ta.LastContributionDate IS NULL THEN 'No Contributions'
        ELSE 'Active Contributor'
    END AS ContributionStatus,
    CASE 
        WHEN ta.RecentPostCount = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS UserActivityStatus
FROM 
    Users u
JOIN 
    TotalAggregates ta ON u.Id = ta.UserId
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    u.Reputation > 100 
    AND (ta.LastContributionDate IS NULL OR ta.LastContributionDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
ORDER BY 
    ua.Upvotes DESC NULLS LAST, 
    ua.TotalPosts DESC;
