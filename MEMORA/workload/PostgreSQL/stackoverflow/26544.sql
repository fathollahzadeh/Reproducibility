WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName AS TopUserName,
    tu.Reputation AS TopUserReputation,
    pt.Tag AS PopularTag,
    pt.TagCount AS PopularTagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.Tag IN (
        SELECT 
            UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.Id
    )
ORDER BY 
    tu.Reputation DESC, 
    pt.TagCount DESC;
