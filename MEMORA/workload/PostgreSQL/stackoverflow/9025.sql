WITH UserReputation AS (
    SELECT Id, Reputation, UpVotes, DownVotes, (UpVotes - DownVotes) AS NetVotes
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.AcceptedAnswerId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, a.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.CreationDate, 
        ps.Score, 
        ps.ViewCount, 
        ps.AcceptedAnswerId, 
        ps.CommentCount, 
        ps.VoteCount,
        ur.Reputation
    FROM PostStats ps
    JOIN UserReputation ur ON ps.PostId = ur.Id
    ORDER BY ps.Score DESC, ps.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.Reputation
FROM TopPosts tp
JOIN Badges b ON b.UserId = tp.PostId
WHERE b.Class = 1
ORDER BY tp.Reputation DESC;
