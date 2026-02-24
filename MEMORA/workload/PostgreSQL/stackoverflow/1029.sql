WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
      AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.ClosedDate IS NULL
    GROUP BY p.Id
)
SELECT 
    up.UserId,
    COALESCE(up.BadgeCount, 0) AS TotalBadges,
    COALESCE(up.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(up.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(up.BronzeBadgeCount, 0) AS BronzeBadges,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    COALESCE(pi.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pi.DownVotes, 0) AS TotalDownVotes,
    COALESCE(pi.CommentCount, 0) AS TotalComments
FROM UserBadges up
LEFT JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN PostInteractions pi ON rp.Id = pi.PostId
WHERE up.BadgeCount > 0
ORDER BY up.UserId;