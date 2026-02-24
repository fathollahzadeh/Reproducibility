WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    WHERE b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY b.UserId
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    tb.BadgeCount,
    CASE 
        WHEN tb.BadgeCount IS NOT NULL THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.PostId
LEFT JOIN TopBadges tb ON ua.UserId = tb.UserId
WHERE ua.PostCount > 5
ORDER BY ua.TotalUpVotes DESC, ua.PostCount DESC;