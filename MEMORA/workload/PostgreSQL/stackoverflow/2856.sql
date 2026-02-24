WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)
    AND ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '60 days'
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(cp.Comment, 'No comments') AS ClosureComment,
    COALESCE(cp.Text, '') AS ClosureText,
    (rp.UpVotes - rp.DownVotes) AS NetVotes,
    CASE 
        WHEN reputationRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserTier
FROM UserReputation up
JOIN RecentPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN UserBadges ub ON up.UserId = ub.UserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
ORDER BY up.Reputation DESC, rp.CreationDate DESC
LIMIT 100;