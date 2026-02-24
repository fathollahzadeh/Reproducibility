WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  
),

UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.Score > 0 THEN p.Id END) AS PositivePosts,
        COUNT(DISTINCT CASE WHEN p.Score < 0 THEN p.Id END) AS NegativePosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),

TagPopularity AS (
    SELECT
        Tag,
        COUNT(DISTINCT PostId) AS PostCount
    FROM
        PostTags
    GROUP BY
        Tag
)

SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.PositivePosts,
    ups.NegativePosts,
    ups.TotalComments,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    tp.Tag,
    tp.PostCount,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = ups.UserId) AS TotalUniqueTagsEngaged,
    (SELECT AVG(p.Score) FROM Posts p WHERE p.OwnerUserId = ups.UserId) AS AveragePostScore
FROM
    UserPostStats ups
JOIN TagPopularity tp ON ups.TotalPosts > 0
ORDER BY
    ups.TotalPosts DESC,
    tp.PostCount DESC
LIMIT 100;