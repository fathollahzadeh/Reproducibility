WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
TopPostsWithUserVotes AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        uvs.DisplayName AS TopVoter,
        uvs.TotalVotes,
        uvs.UpVotes,
        uvs.DownVotes
    FROM PostStats ps
    JOIN UserVoteStats uvs ON uvs.TotalVotes = (SELECT MAX(TotalVotes) FROM UserVoteStats)
    ORDER BY ps.Score DESC, ps.ViewCount DESC
    LIMIT 10
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    TopVoter,
    TotalVotes,
    UpVotes,
    DownVotes
FROM TopPostsWithUserVotes;
