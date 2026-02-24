
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalVotes,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalVotes DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    rt.TagName,
    rt.PostCount,
    rt.TotalVotes,
    rt.AvgUserReputation,
    CASE 
        WHEN rt.AvgUserReputation > 1000 THEN 'Expert'
        WHEN rt.AvgUserReputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice' 
    END AS UserLevel
FROM 
    RankedTags rt
WHERE 
    rt.TagRank <= 10
ORDER BY 
    rt.TagRank;
