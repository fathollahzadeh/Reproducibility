
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.PostsCount,
        ur.Upvotes,
        ur.Downvotes,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostsCount > 0
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '><'))) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.PostsCount,
    tu.Upvotes,
    tu.Downvotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    pt.Tag,
    pt.UsageCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON pt.Tag IN (
        SELECT 
            TRIM(UNNEST(string_to_array(p.Tags, '><')))
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = tu.UserId
    )
ORDER BY 
    tu.Rank, pt.UsageCount DESC;
