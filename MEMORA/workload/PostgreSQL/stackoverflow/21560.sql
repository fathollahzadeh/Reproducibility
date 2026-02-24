
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
), RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        cr.Name AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    AND ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
), Combinations AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AcceptedAnswerId,
        rc.CloseReason,
        ua.Upvotes,
        ua.Downvotes,
        ub.BadgeNames
    FROM RankedPosts rp
    LEFT JOIN RecentCloseReasons rc ON rp.PostId = rc.PostId
    LEFT JOIN UserActivity ua ON rp.OwnerUserId = ua.UserId
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE rp.UserPostRank = 1 
)
SELECT 
    c.PostId,
    c.Title,
    c.CreationDate,
    COALESCE(c.CloseReason, 'No Close Reason') AS CloseReason,
    c.Upvotes,
    c.Downvotes,
    COALESCE(c.BadgeNames, 'No Badges') AS BadgeNames,
    CASE
        WHEN c.Score > 10 THEN 'Highly Popular'
        WHEN c.Score BETWEEN 1 AND 10 THEN 'Moderately Popular'
        ELSE 'Needs Improvement'
    END AS Popularity
FROM Combinations c
ORDER BY c.ViewCount DESC, c.Score DESC
LIMIT 50;
