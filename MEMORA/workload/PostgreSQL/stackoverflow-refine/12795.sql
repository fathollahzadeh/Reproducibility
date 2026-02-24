WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(v.vote_count, 0) AS VoteCount,
        COALESCE(c.comment_count, 0) AS CommentCount,
        COALESCE(a.answer_count, 0) AS AnswerCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS vote_count
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS comment_count
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId AS PostId, COUNT(*) AS answer_count
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.VoteCount,
    ps.CommentCount,
    ps.AnswerCount,
    ps.OwnerReputation,
    pt.Name AS PostTypeName
FROM PostStatistics ps
JOIN PostTypes pt ON ps.PostId = ps.PostId
WHERE ps.ViewCount > 0
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 100;