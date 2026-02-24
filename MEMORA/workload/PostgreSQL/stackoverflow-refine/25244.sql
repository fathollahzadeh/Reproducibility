WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8   
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotedPosts,
        TotalViews,
        AverageBounty,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalViews DESC) AS Rank
    FROM UserActivity
)
SELECT 
    tc.DisplayName,
    tc.TotalPosts,
    tc.TotalComments,
    tc.TotalQuestions,
    tc.TotalAnswers,
    tc.TotalUpvotedPosts,
    tc.TotalViews,
    COALESCE(tc.AverageBounty, 0) AS AverageBounty,
    CASE 
        WHEN tc.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorType
FROM TopContributors tc
WHERE tc.Rank <= 10 OR tc.TotalPosts > 50  
ORDER BY tc.Rank;