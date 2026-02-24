WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2020-01-01' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
TopPosts AS (
    SELECT * FROM RankedPosts WHERE VoteRank <= 10 
)
SELECT
    t.Title,
    t.CreationDate,
    u.DisplayName AS Owner,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    pt.Name AS PostType
FROM TopPosts t
JOIN Users u ON t.OwnerUserId = u.Id
JOIN PostTypes pt ON t.PostTypeId = pt.Id
ORDER BY t.PostTypeId, t.UpVotes DESC;