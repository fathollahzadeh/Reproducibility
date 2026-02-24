
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalDeletions,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END), 0) AS TotalUndeletions
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
EngagementInsights AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.TotalUpvotes,
        ue.TotalDownvotes,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgScore,
        ps.TotalViews
    FROM UserEngagement ue
    LEFT JOIN PostStatistics ps ON ue.UserId = ps.OwnerUserId
)
SELECT 
    ei.DisplayName,
    ei.Reputation,
    ei.TotalUpvotes,
    ei.TotalDownvotes,
    ei.TotalQuestions,
    ei.TotalAnswers,
    ei.AvgScore,
    ei.TotalViews,
    CASE 
        WHEN ei.TotalAnswers > ei.TotalQuestions THEN 'High Answer Rate'
        WHEN ei.TotalUpvotes > ei.TotalDownvotes THEN 'Positive Engagement'
        ELSE 'Needs Improvement'
    END AS EngagementCategory
FROM EngagementInsights ei
WHERE ei.Reputation > 100 
ORDER BY ei.Reputation DESC, ei.TotalUpvotes DESC;
