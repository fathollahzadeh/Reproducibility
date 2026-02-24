WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        Contributors,
        RANK() OVER (ORDER BY TotalViews DESC) AS PopularityRank
    FROM 
        TagStatistics
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - interval '30 days' 
    AND 
        p.PostTypeId = 1 
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.TotalViews,
    pt.AverageScore,
    pt.Contributors,
    rp.Id AS RecentPostId,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViewCount,
    rp.Score AS RecentPostScore
FROM 
    PopularTags pt
LEFT JOIN 
    RecentPosts rp ON pt.TagName = rp.TagName
WHERE 
    pt.PopularityRank <= 5 
ORDER BY 
    pt.PopularityRank, rp.CreationDate DESC;