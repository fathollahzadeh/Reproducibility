WITH RecursiveTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
AggregatedTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        RecursiveTags
    GROUP BY 
        TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
),
MostVotedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title
    ORDER BY 
        Score DESC
    LIMIT 10
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        bc.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
    WHERE 
        u.Reputation > 1000  
)
SELECT 
    at.TagName,
    at.TagUsageCount,
    mvp.PostId,
    mvp.Title AS MostVotedPost,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount
FROM 
    AggregatedTags at
CROSS JOIN 
    MostVotedPosts mvp
CROSS JOIN 
    TopUsers tu
ORDER BY 
    at.TagUsageCount DESC, 
    mvp.Score DESC, 
    tu.Reputation DESC;