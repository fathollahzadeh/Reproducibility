
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.ViewCount
),
RecentPostHistory AS (
    SELECT 
        h.PostId,
        h.UserId,
        ph.Name AS HistoryType,
        h.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY h.PostId ORDER BY h.CreationDate DESC) AS RecentHistoryRank
    FROM PostHistory h
    JOIN PostHistoryTypes ph ON h.PostHistoryTypeId = ph.Id
    WHERE h.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    u.Location,
    ub.BadgeCount,
    ub.MaxBadgeClass,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.UpVotes,
    pp.DownVotes,
    rp.HistoryType AS RecentActionType,
    rp.CreationDate AS RecentActionDate
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pp ON pp.PopularityRank = 1  
LEFT JOIN RecentPostHistory rp ON u.Id = rp.UserId AND rp.RecentHistoryRank = 1  
WHERE 
    (ub.BadgeCount IS NULL OR ub.MaxBadgeClass = 1)  
    AND (u.Location IS NOT NULL OR (u.AboutMe IS NOT NULL AND LENGTH(u.AboutMe) > 100))  
    AND pp.ViewCount >= 1000  
ORDER BY u.Reputation DESC
LIMIT 10;
