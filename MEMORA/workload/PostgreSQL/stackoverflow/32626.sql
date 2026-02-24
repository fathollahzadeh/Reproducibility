
WITH RECURSIVE UserVotes AS (
    SELECT u.Id AS UserId, u.DisplayName, v.VoteTypeId, 1 AS VoteCount
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    WHERE v.VoteTypeId IN (2, 3)  
    UNION ALL
    SELECT u.Id, u.DisplayName, v.VoteTypeId, uv.VoteCount + 1
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    JOIN UserVotes uv ON uv.UserId = u.Id
    WHERE uv.VoteCount < 10  
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN bh.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory bh ON p.Id = bh.PostId
    WHERE p.CreationDate >= '2023-01-01'  
    GROUP BY p.Id, p.Title, p.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    uv.DisplayName AS TopVoter,
    uv.VoteCount
FROM PostStatistics ps
LEFT JOIN UserBadges ub ON ub.UserId = ps.PostId  
LEFT JOIN (
    SELECT UserId, DisplayName, SUM(VoteCount) AS VoteCount
    FROM UserVotes
    GROUP BY UserId, DisplayName
) uv ON 1=1  
WHERE ps.CloseReopenedCount > 0  
ORDER BY ps.UpVotes DESC, ps.CommentCount DESC;
