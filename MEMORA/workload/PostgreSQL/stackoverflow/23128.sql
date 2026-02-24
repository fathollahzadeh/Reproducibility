
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        RANK() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostClosureDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TaggedPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    R.PostId,
    R.Title,
    COALESCE(ups.PostCount, 0) AS PostCount,
    ups.TotalViews,
    ups.AverageScore,
    R.ViewCount AS RecentViews,
    COALESCE(pc.CloseCount, 0) AS ClosureCount,
    pt.TagName
FROM 
    RankedPosts R
LEFT JOIN 
    UserPostStats ups ON R.PostId = ups.UserId
LEFT JOIN 
    PostClosureDetails pc ON R.PostId = pc.PostId
LEFT JOIN 
    PopularTags pt ON pt.TaggedPosts = R.PostId
WHERE 
    R.RankScore <= 10
ORDER BY 
    RecentViews DESC, 
    ClosureCount DESC
LIMIT 50
OFFSET 0;
