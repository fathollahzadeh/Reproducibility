WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopContributors,
        TotalBounties,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        TagStats
)
SELECT 
    TagName, 
    PostCount, 
    TotalViews, 
    AverageScore, 
    TopContributors, 
    TotalBounties,
    ViewRank,
    PostRank
FROM 
    TopTags
WHERE 
    ViewRank <= 5 OR PostRank <= 5
ORDER BY 
    GREATEST(ViewRank, PostRank);