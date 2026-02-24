WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserPostDetails AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COALESCE(SUM(rp.ViewCount), 0) AS TotalViews
    FROM 
        UserReputation up
    LEFT JOIN 
        RecentPosts rp ON up.UserId = rp.OwnerUserId
    GROUP BY 
        up.UserId, up.DisplayName
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    ud.TotalPosts,
    ud.TotalScore,
    ud.TotalViews,
    CASE 
        WHEN ud.TotalPosts > 10 THEN 'Active'
        WHEN ud.TotalPosts BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS ActivityLevel,
    COALESCE(SUM(b.Id), 0) AS TotalBadges,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes
FROM 
    UserPostDetails ud
LEFT JOIN 
    Badges b ON ud.UserId = b.UserId
LEFT JOIN 
    Posts p ON ud.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    ud.UserId, ud.DisplayName, ud.TotalPosts, ud.TotalScore, ud.TotalViews
ORDER BY 
    ud.TotalScore DESC, ud.TotalViews DESC
LIMIT 20;