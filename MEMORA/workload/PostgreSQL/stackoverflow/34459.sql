WITH RECURSIVE UserBadges AS (
    SELECT u.Id AS UserId, u.DisplayName, b.Name AS BadgeName, b.Class, b.Date,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
    WHERE b.Class = 1 
),
PostViews AS (
    SELECT p.Id AS PostId, p.OwnerUserId, COUNT(v.Id) AS VoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId
),
ClosedPosts AS (
    SELECT ph.PostId, ph.CreationDate, p.Title,
           RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
),
ActiveUsers AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           MAX(CASE WHEN p.OwnerUserId IS NOT NULL THEN 'Active' ELSE 'Inactive' END) AS UserActivity
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    ub.BadgeName AS GoldBadge,
    COALESCE(pv.VoteCount, 0) AS TotalVotes,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    cp.Title AS ClosedPostTitle,
    cp.CreationDate AS ClosedOn,
    au.UserActivity
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId AND ub.BadgeRank = 1
LEFT JOIN PostViews pv ON u.Id = pv.OwnerUserId
LEFT JOIN ClosedPosts cp ON u.Id = cp.PostId AND cp.ClosureRank = 1
LEFT JOIN ActiveUsers au ON u.Id = au.UserId
WHERE (ub.BadgeName IS NOT NULL OR pv.VoteCount > 0 OR cp.Title IS NOT NULL OR au.UserActivity = 'Active')
ORDER BY u.Reputation DESC, u.DisplayName;