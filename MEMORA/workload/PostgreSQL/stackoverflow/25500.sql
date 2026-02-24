WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(u.Reputation) AS AverageReputation
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%<' || t.TagName || '>%' 
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),
PopularTags AS (
    SELECT
        TagName,
        PostCount,
        PopularPostCount,
        AverageReputation,
        RANK() OVER (ORDER BY PopularPostCount DESC) AS PopularityRank
    FROM
        TagStatistics
),
UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AverageReputation
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        BadgeCount,
        AverageReputation,
        RANK() OVER (ORDER BY BadgeCount DESC, AverageReputation DESC) AS UserRank
    FROM
        UserBadgeCounts
)
SELECT
    pt.TagName,
    pt.PostCount,
    pt.PopularPostCount,
    pt.AverageReputation,
    tu.DisplayName AS TopUser,
    tu.BadgeCount,
    tu.AverageReputation AS UserAverageReputation
FROM
    PopularTags pt
JOIN
    TopUsers tu ON pt.PopularityRank = tu.UserRank
WHERE
    pt.PostCount > 5
ORDER BY
    pt.PopularPostCount DESC, tu.BadgeCount DESC;