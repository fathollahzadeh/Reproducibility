WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        ARRAY_AGG(DISTINCT u.DisplayName) AS UsersContributing,
        STRING_AGG(DISTINCT p.Title, '; ') AS PostTitles
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%<' || t.TagName || '>%'  
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        UsersContributing,
        PostTitles,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.TotalScore,
    pt.Rank,
    pt.UsersContributing,
    pt.PostTitles
FROM 
    PopularTags pt
WHERE 
    pt.Rank <= 5  
ORDER BY 
    pt.TotalScore DESC;