
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 END, 0)) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalViews,
    ua.UpVotes,
    ua.DownVotes,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pt.Tag,
    pt.TagCount,
    RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
FROM UserActivity ua
LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
JOIN PopularTags pt ON ua.PostCount > 5
WHERE ua.PostCount > 0 AND (ua.TotalViews IS NOT NULL OR ua.UpVotes > 0)
ORDER BY ua.PostCount DESC, ua.TotalViews DESC;
