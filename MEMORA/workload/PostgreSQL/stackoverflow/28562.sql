WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    t.AvgUserReputation,
    ph.CreationDate AS LastPostEditedDate,
    u.DisplayName AS LastEditorDisplayName
FROM 
    TopTags t
LEFT JOIN 
    Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id 
    AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
LEFT JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank;