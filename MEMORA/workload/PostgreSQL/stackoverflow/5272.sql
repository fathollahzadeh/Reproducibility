
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(vt.VoteCount, 0)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) vt ON p.Id = vt.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalVotes,
        RANK() OVER (ORDER BY TotalVotes DESC, TotalViews DESC) AS Rank
    FROM UserStats
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalViews,
    t.TotalVotes,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM TopUsers t
WHERE t.TotalPosts > 0
ORDER BY t.Rank, t.TotalVotes DESC;
