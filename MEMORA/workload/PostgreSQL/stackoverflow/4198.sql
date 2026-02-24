
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5)
    GROUP BY ph.PostId
)
SELECT 
    up.DisplayName,
    COALESCE(rp.Title, 'No Posts Found') AS LatestPostTitle,
    up.NetVotes,
    COALESCE(phed.EditCount, 0) AS TotalEdits,
    phed.LastEditDate,
    CASE 
        WHEN up.NetVotes > 10 THEN 'Active Contributor'
        WHEN up.NetVotes BETWEEN 1 AND 10 THEN 'Moderate Contributor'
        ELSE 'New User'
    END AS UserLevel
FROM UserStats up
LEFT JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN PostHistoryStats phed ON rp.Id = phed.PostId
WHERE up.BadgeCount > 0 OR up.NetVotes > 0
ORDER BY up.NetVotes DESC
LIMIT 100 OFFSET 0;
