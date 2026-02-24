
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ', ')) AS t(TagName) ON TRUE
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedPosts
    FROM 
        Posts p 
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
ActivitySummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalUpvotes,
        ua.TotalDownvotes,
        COALESCE(cps.ClosedPosts, 0) AS ClosedPosts,
        ua.Tags
    FROM 
        UserActivity ua
    LEFT JOIN 
        ClosedPostStats cps ON ua.UserId = cps.OwnerUserId
)
SELECT 
    asu.UserId,
    asu.DisplayName,
    asu.TotalPosts,
    asu.TotalQuestions,
    asu.TotalAnswers,
    asu.TotalUpvotes,
    asu.TotalDownvotes,
    asu.ClosedPosts,
    CASE 
        WHEN asu.TotalPosts > 100 THEN 'Active Contributor'
        WHEN asu.TotalPosts > 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM 
    ActivitySummary asu
ORDER BY 
    asu.TotalUpvotes DESC, 
    asu.TotalPosts DESC 
FETCH FIRST 20 ROWS ONLY;
