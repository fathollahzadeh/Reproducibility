
WITH TagDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS SplitTags
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.AcceptedAnswerId) AS AcceptedAnswers,
        AVG(p.Score) AS AvgScore
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
)
SELECT
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    ud.GoldBadges,
    ud.SilverBadges,
    ud.BronzeBadges,
    ps.TotalPosts,
    ps.AcceptedAnswers,
    ps.AvgScore,
    ARRAY_AGG(DISTINCT td.SplitTags) AS UniqueTags,
    COUNT(td.PostId) AS QuestionsCount
FROM
    UserReputation ud
JOIN
    PostStats ps ON ud.UserId = ps.OwnerUserId
LEFT JOIN
    TagDetails td ON ps.OwnerUserId = (
        SELECT OwnerUserId FROM Posts WHERE Id = td.PostId
    )
GROUP BY
    ud.DisplayName, ud.Reputation, ud.BadgeCount, ud.GoldBadges, 
    ud.SilverBadges, ud.BronzeBadges, ps.TotalPosts, 
    ps.AcceptedAnswers, ps.AvgScore
ORDER BY
    ud.Reputation DESC, ps.TotalPosts DESC;
