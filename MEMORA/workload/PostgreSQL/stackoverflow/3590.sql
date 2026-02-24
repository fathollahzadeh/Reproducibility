
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore
FROM UserStats us
LEFT JOIN RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE us.Reputation > 1000
    AND us.BadgeCount > 2
ORDER BY us.Reputation DESC, us.DisplayName
LIMIT 10
OFFSET 0;
