
WITH UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.ViewCount) AS AverageViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserAggregates AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.AverageViews, 0) AS AverageViews,
        COALESCE(ps.LastPostDate, DATE '1900-01-01') AS LastPostDate 
    FROM Users u
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT
    ua.DisplayName,
    ua.Reputation,
    ua.BadgeCount,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.AverageViews,
    ua.LastPostDate,
    CASE 
        WHEN ua.Reputation > 1000 AND ua.BadgeCount > 5 THEN 'High Performer'
        WHEN ua.Reputation > 1000 THEN 'Experienced'
        WHEN ua.BadgeCount > 5 THEN 'Enthusiast'
        ELSE 'Newcomer'
    END AS UserCategory,
    ARRAY_AGG(DISTINCT t.TagName) AS AssociatedTags,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT CONCAT(vt.Name, ' (', v.CreationDate, ')'), '; ') AS LatestVotes
FROM UserAggregates ua
LEFT JOIN Posts p ON ua.Id = p.OwnerUserId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
LEFT JOIN LATERAL (
    SELECT 
        t.TagName
    FROM UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS t(TagName)
) t ON true
GROUP BY ua.Id, ua.DisplayName, ua.Reputation, ua.BadgeCount, ua.TotalPosts, ua.Questions, ua.Answers, ua.AverageViews, ua.LastPostDate
HAVING COUNT(DISTINCT p.Id) > 0
ORDER BY ua.Reputation DESC, ua.TotalPosts DESC
LIMIT 10;
