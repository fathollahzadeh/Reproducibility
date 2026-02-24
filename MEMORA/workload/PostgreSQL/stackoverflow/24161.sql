
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score,
        COUNT(CASE WHEN c.Score IS NOT NULL THEN c.Id END) AS CommentCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgActivityTime
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
TopBadgedUsers AS (
    SELECT 
        ub.UserId,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ub.BadgeCount DESC) AS BadgeRank
    FROM UserBadges ub
    WHERE ub.BadgeCount > 0
),
ActivePosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.Score,
        ps.CommentCount,
        u.Reputation,
        pb.BadgeCount AS UserBadgeCount
    FROM PostScores ps
    INNER JOIN Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN UserBadges pb ON u.Id = pb.UserId
    WHERE ps.Score > 0
)
SELECT 
    ap.PostId,
    ap.Score,
    ap.CommentCount,
    ap.Reputation,
    CASE 
        WHEN ap.UserBadgeCount IS NULL THEN 'No Badges'
        WHEN ap.UserBadgeCount >= 10 THEN 'Expert Level'
        ELSE 'Novice Level' 
    END AS UserBadgeLevel,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM ActivePosts ap
LEFT JOIN PostLinks pl ON ap.PostId = pl.PostId
WHERE 
    ap.Reputation > 100 AND 
    ap.CommentCount > 5 AND 
    (ap.Score + COALESCE(ap.UserBadgeCount, 0)) > 15
GROUP BY 
    ap.PostId,
    ap.Score,
    ap.CommentCount,
    ap.Reputation,
    ap.UserBadgeCount
HAVING 
    AVG(CASE WHEN ap.Score > 10 THEN 1 ELSE NULL END) > 0.5
ORDER BY UserBadgeLevel DESC, ap.Score DESC
LIMIT 100;
