
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(b.Id) AS BadgeCount,
        AVG(p.ViewCount) AS AvgViews
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        PHT.Name AS CloseReason,
        ph.UserDisplayName AS CloserUser
    FROM PostHistory ph
    JOIN PostHistoryTypes PHT ON PHT.Id = ph.PostHistoryTypeId
    WHERE ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.QuestionCount,
    up.BadgeCount,
    up.AvgViews,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.PostRank,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    cp.CloseReason,
    cp.CloserUser
FROM UserStatistics up
LEFT JOIN RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE NOT EXISTS (
    SELECT 1
    FROM Votes v
    WHERE v.UserId = up.UserId AND v.PostId = rp.PostId AND v.VoteTypeId = 3
)
ORDER BY up.Reputation DESC, rp.ViewCount DESC NULLS LAST
LIMIT 100;
