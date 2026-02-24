WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        AVG(p.ViewCount) AS AverageViews,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        t.Id, t.TagName
),

HighScoringTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.PositiveScoreCount,
        ts.NegativeScoreCount,
        ts.AverageViews,
        ts.AverageReputation
    FROM 
        TagStatistics ts
    WHERE 
        ts.AverageReputation > 1000 AND 
        ts.PositiveScoreCount > ts.NegativeScoreCount
)

SELECT 
    ht.TagName,
    ht.PostCount,
    ht.PositiveScoreCount,
    ht.NegativeScoreCount,
    ht.AverageViews,
    ht.AverageReputation
FROM 
    HighScoringTags ht
ORDER BY 
    ht.AverageViews DESC, 
    ht.PositiveScoreCount DESC;