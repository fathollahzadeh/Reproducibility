
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges,
        (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes v WHERE v.UserId = u.Id) AS TotalUpVotes,
        (SELECT SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes v WHERE v.UserId = u.Id) AS TotalDownVotes
    FROM Users u
    WHERE u.Reputation >= 1000
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CombinedStatistics AS (
    SELECT 
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.TotalBadges,
        us.TotalUpVotes,
        us.TotalDownVotes,
        ps.TotalViews,
        ps.TotalScore,
        ps.TotalQuestions,
        ps.TotalAnswers
    FROM UserStatistics us
    JOIN PostStatistics ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalBadges,
    TotalUpVotes,
    TotalDownVotes,
    TotalViews,
    TotalScore,
    TotalQuestions,
    TotalAnswers,
    (TotalUpVotes - TotalDownVotes) AS NetVotes
FROM CombinedStatistics
ORDER BY Reputation DESC, TotalScore DESC
LIMIT 10;
