WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 52 THEN 1 ELSE 0 END) AS HotCount,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TagRanked AS (
    SELECT 
        TagName,
        PostCount,
        ClosedCount,
        HotCount,
        AverageReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank,
        RANK() OVER (ORDER BY ClosedCount DESC) AS ClosedCountRank,
        RANK() OVER (ORDER BY HotCount DESC) AS HotCountRank,
        RANK() OVER (ORDER BY AverageReputation DESC) AS ReputationRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    ClosedCount,
    HotCount,
    AverageReputation,
    PostCountRank,
    ClosedCountRank,
    HotCountRank,
    ReputationRank,
    (PostCountRank + ClosedCountRank + HotCountRank + ReputationRank) AS OverallRank
FROM 
    TagRanked
ORDER BY 
    OverallRank;
