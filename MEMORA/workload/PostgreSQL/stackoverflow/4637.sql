
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS CloseReason
    FROM PostHistory ph
    INNER JOIN CloseReasonTypes pt ON CAST(ph.Comment AS integer) = pt.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    ub.DisplayName,
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    ub.BadgeCount,
    ub.GoldCount,
    ub.SilverCount,
    ub.BronzeCount,
    COALESCE(cp.CloseReason, 'Open') AS PostStatus,
    ROUND((pd.ViewCount + COALESCE(pd.CommentCount, 0)) / NULLIF(ub.BadgeCount, 0), 2) AS EngagementScore
FROM UserBadges ub
JOIN PostDetails pd ON ub.UserId = pd.OwnerUserId
LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
WHERE pd.PostRank <= 5 AND (ub.BadgeCount > 0 OR cp.PostId IS NOT NULL)
ORDER BY EngagementScore DESC;
