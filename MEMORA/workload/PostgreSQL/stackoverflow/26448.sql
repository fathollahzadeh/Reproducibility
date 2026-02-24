WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViews,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        PositiveVotes,
        NegativeVotes,
        AvgViews,
        ActiveUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagSummary
)
SELECT 
    TagName,
    PostCount,
    PositiveVotes,
    NegativeVotes,
    AvgViews,
    ActiveUsers
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;