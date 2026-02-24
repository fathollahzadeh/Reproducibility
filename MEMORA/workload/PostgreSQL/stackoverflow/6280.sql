WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
PostSummary AS (
    SELECT 
        r.OwnerName,
        COUNT(CASE WHEN r.PostRank = 1 THEN 1 END) AS TopPostCount,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews
    FROM 
        RankedPosts r
    GROUP BY 
        r.OwnerName
),
TagPostCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    ps.OwnerName,
    ps.TopPostCount,
    ps.TotalScore,
    ps.TotalViews,
    ARRAY_AGG(tp.TagName) AS AssociatedTags
FROM 
    PostSummary ps
LEFT JOIN 
    TagPostCount tp ON ps.TopPostCount > 0
GROUP BY 
    ps.OwnerName, ps.TopPostCount, ps.TotalScore, ps.TotalViews
ORDER BY 
    ps.TotalScore DESC, ps.TopPostCount DESC;