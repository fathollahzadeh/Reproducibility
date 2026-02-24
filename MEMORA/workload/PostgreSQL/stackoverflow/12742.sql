WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.AnswerCount) AS TotalAnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalViews,
    us.AverageScore,
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalAnswerCount
FROM Users u
LEFT JOIN UserStats us ON u.Id = us.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
ORDER BY u.Reputation DESC
LIMIT 100;
