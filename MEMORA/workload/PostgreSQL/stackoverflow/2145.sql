
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.PostTypeId, p.CreationDate
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        us.DisplayName AS TopUser,
        us.Rank AS UserRank
    FROM PostStats ps
    JOIN UserVoteStats us ON ps.UpVotes > us.UpVotes
    WHERE us.Rank <= 10
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.CommentCount,
    cs.UpVotes,
    cs.DownVotes,
    COALESCE(NULLIF(cs.TopUser, ''), 'No Votes') AS TopUser,
    CASE 
        WHEN cs.UpVotes - cs.DownVotes > 0 THEN 'Positive'
        WHEN cs.UpVotes - cs.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.CreationDate >= cs.CreationDate AND p2.Id != cs.PostId) AS NewerPostsCount
FROM CombinedStats cs
ORDER BY cs.UpVotes DESC, cs.CommentCount DESC;
