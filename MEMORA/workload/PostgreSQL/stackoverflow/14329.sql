
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
CombinedSummary AS (
    SELECT 
        uvs.UserId,
        uvs.DisplayName,
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.AnswerCount,
        uvs.TotalVotes,
        uvs.UpVotes,
        uvs.DownVotes
    FROM UserVoteSummary uvs
    JOIN PostSummary ps ON uvs.UserId = ps.PostId 
)
SELECT 
    UserId,
    DisplayName,
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    AnswerCount,
    TotalVotes,
    UpVotes,
    DownVotes
FROM CombinedSummary
ORDER BY Score DESC, ViewCount DESC
LIMIT 100;
