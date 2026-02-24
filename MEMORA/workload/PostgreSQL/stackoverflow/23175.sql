
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId IN (10, 11) THEN p.Id END) AS PostVoteCount,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        COALESCE(uv.UpVotesCount, 0) AS UserUpVotes,
        COALESCE(uv.DownVotesCount, 0) AS UserDownVotes,
        (rp.Score - COALESCE(uv.DownVotesCount, 0) + COALESCE(uv.UpVotesCount, 0)) AS AdjustedScore
    FROM RecentPosts rp
    LEFT JOIN UserVoteSummary uv ON rp.OwnerUserId = uv.UserId
    WHERE rp.RowNum = 1
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.UserUpVotes,
    ps.UserDownVotes,
    ps.AdjustedScore,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)) AS BadgeCount
FROM PostSummary ps
WHERE ps.AdjustedScore > (SELECT AVG(AdjustedScore) FROM PostSummary)
ORDER BY ps.AdjustedScore DESC;
