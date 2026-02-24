
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.FavoriteCount, u.Reputation
),
AverageStats AS (
    SELECT 
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        AVG(OwnerReputation) AS AvgOwnerReputation,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(FavoriteCount) AS AvgFavoriteCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM PostStats
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    av.AvgScore,
    av.AvgViewCount,
    av.AvgOwnerReputation,
    av.AvgAnswerCount,
    av.AvgCommentCount,
    av.AvgFavoriteCount,
    av.TotalUpVotes,
    av.TotalDownVotes
FROM PostStats ps
CROSS JOIN AverageStats av
ORDER BY ps.CreationDate DESC
LIMIT 100;
