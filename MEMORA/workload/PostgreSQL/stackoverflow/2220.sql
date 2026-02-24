WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS RecentBadgeNames,
        MAX(b.Date) AS MostRecentBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserRanking AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        rb.RecentBadgeNames,
        RANK() OVER (ORDER BY up.TotalPosts DESC) AS Rank
    FROM 
        UserPosts up
    LEFT JOIN 
        RecentBadges rb ON up.UserId = rb.UserId
)
SELECT 
    ur.DisplayName,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    COALESCE(rb.RecentBadgeNames, 'No badges') AS RecentBadges,
    ur.Rank,
    CASE 
        WHEN ur.TotalPosts IS NULL THEN 'No activity'
        WHEN ur.TotalPosts > 100 THEN 'Top Contributor'
        WHEN ur.TotalPosts BETWEEN 50 AND 100 THEN 'Active Contributor'
        WHEN ur.TotalPosts BETWEEN 1 AND 49 THEN 'New Contributor'
        ELSE 'Unknown Status'
    END AS ContributorStatus
FROM 
    UserRanking ur
LEFT JOIN 
    RecentBadges rb ON ur.UserId = rb.UserId
WHERE 
    ur.Rank <= 10
ORDER BY 
    ur.Rank;
