
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COALESCE(SUM(prv.RevisionCount), 0) AS TotalRevisions
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS RevisionCount
        FROM PostHistory
        GROUP BY PostId
    ) prv ON prv.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalQuestions, TotalAnswers, TotalUpVotes, TotalDownVotes, TotalRevisions,
           RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.TotalRevisions,
    CASE 
        WHEN tu.TotalPosts > 100 THEN 'Active Contributor'
        WHEN tu.TotalPosts BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'New User'
    END AS UserActivityLevel,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM TopUsers tu
LEFT JOIN PostLinks pl ON tu.UserId = pl.PostId
GROUP BY tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalQuestions, tu.TotalAnswers, 
         tu.TotalUpVotes, tu.TotalDownVotes, tu.TotalRevisions, tu.UpVoteRank
HAVING COUNT(DISTINCT pl.RelatedPostId) > 0
ORDER BY tu.UpVoteRank
LIMIT 10;
