
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  
    WHERE p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '3 months'
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.TotalBountySpent,
    ur.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    rph.LastEditDate,
    rph.HistoryCount,
    CASE 
        WHEN ps.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE NULL
    END AS PostRankStatus
FROM UserReputation ur
JOIN PostStatistics ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN RecentPostHistory rph ON ps.PostId = rph.PostId 
WHERE ur.Reputation > 100 
AND ps.CommentCount > 5 
AND (rph.HistoryCount IS NULL OR rph.HistoryCount > 1)
ORDER BY ur.Reputation DESC, ps.ViewCount DESC
LIMIT 50;
