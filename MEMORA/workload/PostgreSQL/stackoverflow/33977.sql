WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT UserId
    FROM UserPostCounts
    WHERE Rank <= 10
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    WHERE b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(up.PostCount, 0) AS PostCount,
    COALESCE(v.PostId, 0) AS PostId,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN b.HighestBadgeClass = 1 THEN 'Gold' 
        WHEN b.HighestBadgeClass = 2 THEN 'Silver' 
        WHEN b.HighestBadgeClass = 3 THEN 'Bronze' 
        ELSE 'None' 
    END AS HighestBadge
FROM Users u
LEFT JOIN UserPostCounts up ON u.Id = up.UserId
LEFT JOIN PostVoteCounts v ON up.UserId = v.PostId
LEFT JOIN UserBadges b ON u.Id = b.UserId
WHERE u.Id IN (SELECT UserId FROM TopUsers)
ORDER BY u.Reputation DESC, PostCount DESC;