
WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COALESCE(ROUND(AVG(p.Score), 2), 0) AS AvgScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, p.OwnerUserId
),
HighScorers AS (
    SELECT 
        OwnerUserId,
        COUNT(PostId) AS HighScoreCount
    FROM PostMetrics
    WHERE AvgScore > 10
    GROUP BY OwnerUserId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges,
        COALESCE(hsc.HighScoreCount, 0) AS HighScoreCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN HighScorers hsc ON u.Id = hsc.OwnerUserId
    WHERE u.Reputation IS NOT NULL AND (u.Reputation > 100 OR ubc.GoldBadges > 0) 
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(u.Reputation, 0) AS Reputation,
    COALESCE(u.GoldBadges, 0) AS GoldBadges,
    COALESCE(u.SilverBadges, 0) AS SilverBadges,
    COALESCE(u.BronzeBadges, 0) AS BronzeBadges,
    u.HighScoreCount,
    CASE 
        WHEN u.Reputation IS NULL THEN 'Reputation Missing'
        WHEN u.HighScoreCount = 0 THEN 'No High Scoring Posts'
        ELSE 'Active Contributor'
    END AS UserStatus
FROM UserWithBadges u
WHERE u.GoldBadges > 0 OR u.HighScoreCount > 0
ORDER BY u.Reputation DESC, u.DisplayName
LIMIT 100;
