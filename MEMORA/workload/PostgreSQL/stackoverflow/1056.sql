WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - u.CreationDate))/3600) AS AvgAgeHours
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.UserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Date) AS LastAwarded
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.PostCount,
    us.AvgAgeHours,
    COALESCE(re.EditCount, 0) AS EditCount,
    re.LastEditDate,
    COALESCE(ub.BadgeCount, 0) AS GoldBadges,
    COALESCE(ub.LastAwarded, NULL) AS LastGoldBadgeAwarded
FROM 
    UserStats us
    LEFT JOIN RecentEdits re ON us.UserId = re.UserId
    LEFT JOIN UserBadges ub ON us.UserId = ub.UserId
WHERE 
    us.UpVotes > us.DownVotes
ORDER BY 
    us.UpVotes DESC
LIMIT 10;