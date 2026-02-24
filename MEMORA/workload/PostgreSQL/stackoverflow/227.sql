WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS Upvotes,
        COALESCE((
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS Downvotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
      AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
QuestionStats AS (
    SELECT 
        q.QuestionId,
        q.Title,
        q.OwnerName,
        q.CreationDate,
        q.AnswerCount,
        q.Score,
        q.Upvotes,
        q.Downvotes,
        (q.Upvotes - q.Downvotes) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY q.OwnerName ORDER BY q.Score DESC) AS OwnerQuestionRank
    FROM RecentQuestions q
),
TopScores AS (
    SELECT 
        QuestionId,
        Title,
        OwnerName,
        CreationDate,
        AnswerCount,
        Score,
        Upvotes,
        Downvotes,
        NetVotes
    FROM QuestionStats
    WHERE OwnerQuestionRank = 1
)

SELECT 
    ts.QuestionId,
    ts.Title,
    ts.OwnerName,
    ts.CreationDate,
    ts.AnswerCount,
    ts.Score,
    ts.Upvotes,
    ts.Downvotes,
    ts.NetVotes,
    (SELECT COUNT(*)
     FROM PostHistory ph
     WHERE ph.PostId = ts.QuestionId 
       AND ph.PostHistoryTypeId IN (10, 11) 
    ) AS CloseReopenCount
FROM TopScores ts
LEFT JOIN Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = ts.OwnerName LIMIT 1)
WHERE b.Class = 1 OR b.Class = 2 
ORDER BY ts.NetVotes DESC, ts.CreationDate DESC;