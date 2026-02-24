WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), ContentQuality AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.Score IS NOT NULL
), UserPostQuality AS (
    SELECT 
        us.UserId,
        COUNT(cp.PostId) AS HighQualityPosts
    FROM UserScoreSummary us
    JOIN ContentQuality cp ON us.UserId = cp.PostId
    WHERE cp.PostRank <= 5
    GROUP BY us.UserId
), FinalMetrics AS (
    SELECT 
        us.UserId,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(upq.HighQualityPosts, 0) AS HighQualityPosts
    FROM UserScoreSummary us
    LEFT JOIN UserPostQuality upq ON us.UserId = upq.UserId
)
SELECT 
    u.DisplayName,
    f.TotalUpVotes,
    f.TotalDownVotes,
    f.GoldBadges,
    f.SilverBadges,
    f.BronzeBadges,
    f.HighQualityPosts,
    CASE 
        WHEN f.TotalUpVotes > f.TotalDownVotes THEN 'Positive'
        WHEN f.TotalUpVotes < f.TotalDownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM FinalMetrics f
JOIN Users u ON f.UserId = u.Id
ORDER BY f.TotalUpVotes - f.TotalDownVotes DESC;
