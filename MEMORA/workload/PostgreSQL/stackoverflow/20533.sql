
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
PostActivity AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.CreationDate) AS EditCount,
        MAX(p.CreationDate) AS PostCreationDate,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureChanges
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.ViewCount > 1000
)
SELECT 
    ups.DisplayName,
    ups.UpVotes,
    uvs.DownVotes,
    ta.TagName,
    ps.Title AS PopularPost,
    ps.ViewCount,
    ps.Score,
    pa.CommentCount,
    pa.EditCount,
    pa.ClosureChanges
FROM UserVoteStats ups
JOIN UserVoteStats uvs ON ups.UserId = uvs.UserId
JOIN TagStats ta ON ups.UpVotes > 10 AND ta.PostCount > 1
JOIN RankedPosts ps ON ps.PostRank <= 5
JOIN PostActivity pa ON ps.Id = pa.PostId
WHERE ups.UpVotes > uvs.DownVotes
AND pa.EditCount > 0
AND ta.TotalViews > 50
AND ps.Score IS NOT NULL 
ORDER BY ups.UpVotes DESC, ps.ViewCount DESC;
