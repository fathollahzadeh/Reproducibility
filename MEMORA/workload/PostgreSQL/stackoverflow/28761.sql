WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS AverageViews,
        SUM(CASE WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = p.Id) THEN 1 ELSE 0 END) AS CommentedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageViews,
        CommentedPosts,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS Rank
    FROM 
        TagStatistics
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalPostViews,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
Benchmark AS (
    SELECT 
        t.TagName,
        u.DisplayName AS TopUser,
        u.TotalPosts,
        u.TotalPostViews,
        t.PostCount,
        t.TotalViews,
        t.AverageViews,
        t.CommentedPosts
    FROM 
        TopTags t
    JOIN 
        UserActivity u ON t.PostCount > 10 
    WHERE 
        EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.UserId AND p.Tags LIKE '%' || t.TagName || '%')
    ORDER BY 
        t.Rank, u.TotalPostViews DESC
)
SELECT 
    TagName,
    TopUser,
    TotalPosts,
    TotalPostViews,
    PostCount,
    TotalViews,
    AverageViews,
    CommentedPosts
FROM 
    Benchmark
LIMIT 20;