WITH PostTagStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        COUNT(DISTINCT mh.UserId) AS TotalModerationHistory,
        COALESCE(SUM(CASE WHEN mh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalClosures,
        COALESCE(SUM(CASE WHEN mh.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS TotalReopens
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0  
    LEFT JOIN 
        PostHistory mh ON mh.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CreationDate
),
UserPostEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS TotalAnswered,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighEngagementPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        u.Id, u.DisplayName
),
BenchmarkingResults AS (
    SELECT 
        pts.PostId,
        pts.Title,
        pts.TagsList,
        ups.DisplayName AS UserDisplayName,
        ups.TotalPosts,
        ups.TotalViews,
        ups.TotalAnswered,
        ups.HighEngagementPosts,
        pts.TotalModerationHistory,
        pts.TotalClosures,
        pts.TotalReopens
    FROM 
        PostTagStatistics pts
    JOIN 
        UserPostEngagement ups ON pts.PostId = ups.TotalPosts
    ORDER BY 
        pts.ViewCount DESC,  
        ups.TotalPosts DESC   
)
SELECT 
    BenchmarkingResults.*
FROM 
    BenchmarkingResults
WHERE 
    TotalViews > 500  
ORDER BY 
    TotalAnswered DESC;