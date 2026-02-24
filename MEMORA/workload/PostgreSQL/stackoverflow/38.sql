
WITH UserVotes AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes v
    GROUP BY v.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        uv.UpVotes,
        uv.DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
    WHERE u.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY rp.CloseReopenCount ORDER BY rp.CommentCount DESC) AS PopularityRank
    FROM RecentPosts rp
)
SELECT 
    tu.Id AS UserId,
    tu.DisplayName,
    fp.Title AS MostPopularPost,
    fp.CommentCount,
    fp.CloseReopenCount
FROM TopUsers tu
JOIN FilteredPosts fp ON tu.Id = (
    SELECT p.OwnerUserId
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    WHERE v.UserId = tu.Id
    GROUP BY p.OwnerUserId
    ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC
    LIMIT 1
)
WHERE fp.PopularityRank = 1
ORDER BY tu.Reputation DESC;
