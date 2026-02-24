WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(vote_count) AS TotalVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionsAnswered,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        COUNT(DISTINCT ph.Id) AS PostEdits
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS vote_count 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE u.Reputation > 1000 
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY pt.Name
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalVotes,
    ua.QuestionsAnswered,
    ua.AnswersGiven,
    ua.PostEdits,
    ps.PostType,
    ps.PostCount AS TotalPostsOfType,
    ps.AverageScore,
    ps.TotalViews
FROM UserActivity ua
CROSS JOIN PostSummary ps
ORDER BY ua.TotalVotes DESC, ua.PostCount DESC, ps.TotalViews DESC
LIMIT 100;