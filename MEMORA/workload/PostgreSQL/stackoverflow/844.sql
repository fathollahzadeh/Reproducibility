
WITH UserStats AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        Views,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS QuestionRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.Rank,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    tq.Title AS TopQuestionTitle,
    tq.Score AS TopQuestionScore,
    tq.CommentCount AS TopQuestionComments,
    tq.CreationDate AS TopQuestionDate
FROM UserStats us
LEFT JOIN Users u ON us.UserId = u.Id
LEFT JOIN PostStats ps ON ps.OwnerUserId = u.Id
LEFT JOIN TopQuestions tq ON tq.QuestionRank = 1
WHERE u.Reputation > 1000
AND ps.TotalPosts IS NOT NULL
ORDER BY u.Reputation DESC;
