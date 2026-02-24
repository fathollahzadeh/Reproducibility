WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.Views,
    u.UpVotes,
    u.DownVotes,
    u.PostCount AS TotalPostsByUser,
    COALESCE(ps.TotalPosts, 0) AS TotalPostsByOwner,
    COALESCE(ps.Questions, 0) AS TotalQuestions,
    COALESCE(ps.Answers, 0) AS TotalAnswers,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.AvgScore, 0) AS AverageScore,
    u.BadgeCount AS TotalBadges
FROM UserStats u
LEFT JOIN PostStats ps ON u.UserId = ps.OwnerUserId
ORDER BY u.Reputation DESC, u.Views DESC;