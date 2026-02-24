WITH RECURSIVE UserHierarchy AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.Id AS RootUserId
    FROM Users u
    WHERE u.Reputation > 1000  
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, uh.RootUserId
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.RootUserId 
    WHERE u.Reputation < uh.Reputation  
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'  
    GROUP BY p.Id, vs.UpVotes, vs.DownVotes
),
FilteredPosts AS (
    SELECT
        pa.PostId,
        pa.Title,
        pa.ViewCount,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER(ORDER BY pa.ViewCount DESC, pa.CommentCount DESC) AS post_rank
    FROM PostActivity pa
    JOIN Users u ON pa.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
    WHERE pa.UpVotes - pa.DownVotes > 0  
)
SELECT
    uh.DisplayName AS UserDisplayName,
    uh.Reputation AS UserReputation,
    fp.Title AS PostTitle,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes
FROM FilteredPosts fp
JOIN UserHierarchy uh ON fp.OwnerDisplayName = uh.DisplayName
WHERE fp.post_rank <= 10  
ORDER BY uh.Reputation DESC, fp.UpVotes DESC;