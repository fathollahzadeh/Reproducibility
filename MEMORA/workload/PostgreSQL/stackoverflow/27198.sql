
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        ub.GoldBadges, 
        ub.SilverBadges, 
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 0
),
TagPostStats AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagPostStats
)
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.BadgeCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    pt.Tag,
    pt.PostCount,
    pt.TotalViews,
    pt.AvgScore
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.TagRank = 1 
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.Reputation DESC;
