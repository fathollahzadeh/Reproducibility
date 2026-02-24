
WITH UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(EXTRACT(EPOCH FROM COALESCE(p.LastActivityDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate)) AS AvgResponseTime,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON t.TagName <> ''
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ProfileSummary AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.Reputation,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        up.TotalViews,
        up.TotalUpvotes,
        up.TotalDownvotes,
        up.AvgResponseTime,
        up.AssociatedTags,
        RANK() OVER (ORDER BY up.TotalPosts DESC) AS PostRanking,
        RANK() OVER (ORDER BY up.TotalUpvotes DESC) AS UpvoteRanking,
        RANK() OVER (ORDER BY up.Reputation DESC) AS ReputationRanking
    FROM UserPerformance up
),
TopProfiles AS (
    SELECT 
        ps.*,
        CASE 
            WHEN ps.PostRanking <= 10 THEN 'Top 10 by Post Count'
            WHEN ps.UpvoteRanking <= 10 THEN 'Top 10 by Upvotes'
            WHEN ps.ReputationRanking <= 10 THEN 'Top 10 by Reputation'
            ELSE 'General User'
        END AS UserCategory
    FROM ProfileSummary ps
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalUpvotes,
    TotalDownvotes,
    AvgResponseTime,
    AssociatedTags,
    UserCategory
FROM TopProfiles
WHERE TotalPosts > 0
ORDER BY Reputation DESC, TotalUpvotes DESC, TotalPosts DESC;
