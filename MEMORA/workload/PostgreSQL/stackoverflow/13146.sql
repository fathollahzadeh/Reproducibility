
WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.AcceptedAnswerId
),

PopularTags AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = p.Tags::integer
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.HasAcceptedAnswer,
    p.CommentCount,
    pt.TagName AS PopularTag
FROM UserVoteStats u
JOIN PostStats p ON u.UpVotes > 0
CROSS JOIN PopularTags pt
WHERE pt.PostCount > 0
ORDER BY u.TotalVotes DESC, p.Score DESC
LIMIT 50;
