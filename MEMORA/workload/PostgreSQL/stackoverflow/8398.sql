WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        p.Owner,
        COUNT(p.PostId) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        RankedPosts p
    GROUP BY 
        p.Owner
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT 
    ps.Owner,
    ps.TotalPosts,
    ps.PositivePosts,
    ps.PopularPosts,
    ps.AvgScore,
    re.UserDisplayName AS LastEditor,
    re.CreationDate AS LastEditDate,
    re.Comment AS LastEditComment
FROM 
    PostStats ps
LEFT JOIN 
    RecentEdits re ON ps.Owner = re.UserDisplayName
WHERE 
    ps.TotalPosts > 10
ORDER BY 
    ps.AvgScore DESC, 
    ps.TotalPosts DESC
LIMIT 50;