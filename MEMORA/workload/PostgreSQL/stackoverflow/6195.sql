
WITH UserVotes AS (
    SELECT 
        v.UserId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    GROUP BY v.UserId, v.VoteTypeId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.VoteCount, 0) AS TotalVotes
    FROM Users u
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
    WHERE u.Reputation >= 1000
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedLinksCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.OwnerUserId,
        pm.UpVotes,
        pm.DownVotes,
        pm.CommentCount,
        pm.RelatedLinksCount,
        RANK() OVER (ORDER BY pm.UpVotes DESC, pm.CommentCount DESC) AS PostRank
    FROM PostMetrics pm
)
SELECT 
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.RelatedLinksCount,
    rp.PostRank
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
WHERE rp.PostRank <= 10
ORDER BY rp.PostRank;
