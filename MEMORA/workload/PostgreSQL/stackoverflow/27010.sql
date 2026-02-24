WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(u.Reputation) AS AverageUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        PopularPostCount,
        AverageUserReputation,
        TopContributors,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),
TagPoll AS (
    SELECT 
        m.TagName,
        m.PostCount,
        m.PopularPostCount,
        m.AverageUserReputation,
        m.TopContributors,
        RANK() OVER (ORDER BY m.PopularPostCount DESC) AS PopularityRank,
        ROW_NUMBER() OVER (PARTITION BY m.TagName ORDER BY m.AverageUserReputation DESC) AS UserReputationRank
    FROM 
        MostActiveTags m
)
SELECT 
    t.TagName,
    t.PostCount,
    t.PopularPostCount,
    t.AverageUserReputation,
    t.TopContributors,
    t.PopularityRank,
    t.UserReputationRank
FROM 
    TagPoll t
WHERE 
    t.UserReputationRank = 1
ORDER BY 
    t.PopularityRank;
