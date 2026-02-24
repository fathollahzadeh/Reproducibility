WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        AVG(extract(epoch from (COALESCE(p.LastActivityDate, cast('2024-10-01 12:34:56' as timestamp)) - p.CreationDate))) AS AvgPostAge
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeDistribution AS (
    SELECT 
        CASE 
            WHEN Class = 1 THEN 'Gold'
            WHEN Class = 2 THEN 'Silver'
            WHEN Class = 3 THEN 'Bronze'
            ELSE 'Unknown' 
        END AS BadgeClass,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        Class
),
PostsStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
)
SELECT 
    a.UserId, 
    a.DisplayName, 
    a.TotalPosts,
    a.TotalQuestions, 
    a.TotalAnswers, 
    a.TotalUpvotes, 
    a.TotalDownvotes, 
    a.TotalBadges, 
    a.AvgPostAge,
    bd.BadgeClass,
    bd.BadgeCount,
    ps.TotalPosts AS OverallPosts,
    ps.TotalQuestions AS OverallQuestions,
    ps.TotalAnswers AS OverallAnswers
FROM 
    UserActivity a
LEFT JOIN 
    BadgeDistribution bd ON TRUE
CROSS JOIN 
    PostsStats ps
ORDER BY 
    a.TotalPosts DESC, a.TotalUpvotes DESC
LIMIT 100;