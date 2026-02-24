
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        AVG(COALESCE(c.CommentsCount, 0)) OVER (PARTITION BY p.OwnerUserId) AS AvgComments,
        MAX(p.CreationDate) OVER (PARTITION BY p.OwnerUserId) AS LastPostDate
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentsCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT
        rp.OwnerDisplayName,
        COUNT(DISTINCT rp.Id) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(CASE WHEN cp.CloseVoteCount IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount,
        AVG(rp.AvgComments) AS AverageComments,
        MAX(rp.LastPostDate) AS LastPostDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    *,
    CASE 
        WHEN TotalPosts > 10 THEN 'Active Contributor' 
        WHEN TotalPosts BETWEEN 1 AND 10 THEN 'New Contributor' 
        ELSE 'Inactive Contributor' 
    END AS ContributorStatus
FROM 
    FinalResults
WHERE 
    LastPostDate >= DATE '2024-10-01' - INTERVAL '30 days'
ORDER BY 
    TotalViews DESC, 
    TotalPosts DESC;
