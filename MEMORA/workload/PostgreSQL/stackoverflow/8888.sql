
WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 1000
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p2.Id) AS LinkedPosts
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Posts p2 ON pl.RelatedPostId = p2.Id
    GROUP BY p.Id, p.Title
),

TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.TotalComments,
        ps.UpVotes,
        ps.DownVotes,
        ps.LinkedPosts,
        u.Reputation AS UserReputation
    FROM PostStats ps
    JOIN Posts p ON ps.PostId = p.Id
    JOIN UserReputation u ON p.OwnerUserId = u.Id
    WHERE ps.UpVotes > ps.DownVotes 
    ORDER BY ps.UpVotes DESC
    LIMIT 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.TotalComments,
    tp.UpVotes,
    tp.DownVotes,
    tp.LinkedPosts,
    tp.UserReputation
FROM TopPosts tp
ORDER BY tp.UserReputation DESC;
