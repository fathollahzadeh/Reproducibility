
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TagUsage AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
),
ActiveUsers AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEdits
    FROM PostHistory ph
    GROUP BY UserId
),
UserPostEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(us.TotalPosts, 0) AS TotalPosts,
        COALESCE(us.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(us.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(us.AcceptedAnswers, 0) AS AcceptedAnswers,
        COALESCE(au.CloseActions, 0) AS CloseActions,
        COALESCE(au.SuggestedEdits, 0) AS SuggestedEdits,
        u.DisplayName,
        u.Reputation
    FROM Users u
    LEFT JOIN UserStats us ON u.Id = us.UserId
    LEFT JOIN ActiveUsers au ON u.Id = au.UserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalQuestions,
    up.TotalAnswers,
    up.AcceptedAnswers,
    up.CloseActions,
    up.SuggestedEdits,
    tg.TagName,
    tg.PostCount
FROM UserPostEngagement up
JOIN TagUsage tg ON up.TotalPosts > 0
ORDER BY up.Reputation DESC, up.TotalPosts DESC, tg.PostCount DESC
LIMIT 10;
