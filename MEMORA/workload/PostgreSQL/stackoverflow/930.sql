WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        pm.OwnerUserId,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        RANK() OVER (PARTITION BY pm.OwnerUserId ORDER BY pm.UpVotes DESC) AS PostRank
    FROM PostMetrics pm
)
SELECT 
    u.DisplayName AS UserName,
    ub.BadgeCount,
    rp.PostId,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.PostRank,
    CASE 
        WHEN rp.PostRank <= 3 THEN 'Top Post'
        WHEN rp.CommentCount > 10 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE (ub.BadgeCount IS NULL OR ub.BadgeCount > 0)
AND (rp.UpVotes > 5 OR rp.CommentCount > 5)
ORDER BY UserName, PostCategory;