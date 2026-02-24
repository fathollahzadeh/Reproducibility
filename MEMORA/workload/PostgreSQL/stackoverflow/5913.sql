
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 0
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UniqueUpVoters,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS UniqueDownVoters,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.UniqueUpVoters,
        ps.UniqueDownVoters,
        ps.HistoryCount,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    ru.DisplayName AS TopUser,
    tp.Title AS PostTitle,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.UniqueUpVoters,
    tp.UniqueDownVoters,
    tp.HistoryCount
FROM TopPosts tp
JOIN RankedUsers ru ON ru.UserId IN (
    SELECT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id = tp.PostId
) 
WHERE tp.PostRank <= 10
ORDER BY tp.PostRank, ru.Reputation DESC;
