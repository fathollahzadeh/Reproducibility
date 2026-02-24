
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PostHistoryLatest AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS LatestRank
    FROM 
        PostHistory ph
)
SELECT 
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore,
    ups.AvgViews,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.CreationDate,
    pp.OwnerDisplayName,
    phl.CreationDate AS LatestChangeDate
FROM 
    UserPostStats ups
LEFT JOIN 
    PopularPosts pp ON pp.PopularityRank <= 10
LEFT JOIN 
    PostHistoryLatest phl ON pp.Id = phl.PostId AND phl.LatestRank = 1
WHERE 
    (ups.PostCount > 10 OR ups.TotalScore > 100)
ORDER BY 
    ups.TotalViews DESC, ups.TotalScore DESC;
