
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId, p.OwnerDisplayName, p.Score, p.ViewCount
),
TopQuestions AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerDisplayName,
        ps.Score,
        ps.ViewCount,
        ue.UserId,
        ue.PostCount,
        ue.QuestionCount,
        ue.AnswerCount
    FROM PostStatistics ps
    JOIN UserEngagement ue ON ps.OwnerDisplayName = ue.DisplayName
    WHERE ue.PostCount > 5
    ORDER BY ps.Score DESC, ps.ViewCount DESC
    FETCH FIRST 10 ROWS ONLY
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.Score,
    tq.ViewCount,
    tq.QuestionCount,
    tq.AnswerCount
FROM TopQuestions tq
JOIN Users u ON tq.OwnerDisplayName = u.DisplayName
WHERE u.Reputation > 1000
ORDER BY tq.Score DESC;
