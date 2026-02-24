
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    WHERE 
        p.PostTypeId = 1
),
TagAnalytics AS (
    SELECT
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        MIN(CreationDate) AS FirstPostDate,
        MAX(CreationDate) AS LastPostDate
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        FirstPostDate,
        LastPostDate,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagAnalytics
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.FirstPostDate,
    t.LastPostDate,
    p.OwnerDisplayName AS TopPostOwner,
    p.Title AS TopPostTitle
FROM 
    TopTags t
JOIN 
    RankedPosts p ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    t.ViewRank <= 5
ORDER BY 
    t.ViewRank, t.TotalViews DESC;
