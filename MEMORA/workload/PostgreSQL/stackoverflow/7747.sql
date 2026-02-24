
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId,
           u.DisplayName AS OwnerDisplayName, COUNT(c.Id) AS CommentCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, u.DisplayName
),
TopUsers AS (
    SELECT u.Id AS UserId, u.DisplayName, SUM(b.Class) AS TotalBadges, COUNT(p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalBadges DESC, PostCount DESC
    LIMIT 10
),
PostVoteSummary AS (
    SELECT p.Id AS PostId,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount,
       rp.UpVotes, rp.DownVotes, tu.DisplayName AS TopUserDisplayName, tu.TotalBadges, tu.PostCount
FROM RecentPosts rp
JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
JOIN PostVoteSummary pvs ON rp.Id = pvs.PostId
ORDER BY rp.CreationDate DESC, rp.Score DESC;
