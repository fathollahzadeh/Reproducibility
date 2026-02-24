
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
), 
TagRanked AS (
    SELECT 
        TagName,
        PostCount,
        PositiveVotes,
        NegativeVotes,
        AvgViews,
        AvgUserReputation,
        RANK() OVER (ORDER BY PostCount DESC, AvgViews DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    tr.TagName,
    tr.PostCount,
    tr.PositiveVotes,
    tr.NegativeVotes,
    tr.AvgViews,
    tr.AvgUserReputation,
    CONCAT(ROUND((CAST(tr.PositiveVotes AS decimal) / NULLIF(tr.PostCount, 0)) * 100, 2), '%') AS PositiveVotePercentage,
    CONCAT(ROUND((CAST(tr.NegativeVotes AS decimal) / NULLIF(tr.PostCount, 0)) * 100, 2), '%') AS NegativeVotePercentage,
    tr.Rank
FROM 
    TagRanked tr
WHERE 
    tr.PostCount > 5
ORDER BY 
    tr.Rank;
