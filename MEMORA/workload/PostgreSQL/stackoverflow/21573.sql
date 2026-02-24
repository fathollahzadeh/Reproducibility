
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years' 
        AND p.Score IS NOT NULL
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(CONCAT(ph.Comment, ' (', ph.CreationDate, ')'), ', ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.TotalScore,
    pp.PostId,
    pp.Title AS TopPostTitle,
    pp.Score AS TopPostScore,
    pp.CreationDate AS TopPostDate,
    ph.LastEditedDate,
    ph.EditComments,
    cp.ClosedDate,
    cp.CloseCount
FROM 
    UserPostStats up
JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId AND pp.PostRank = 1
LEFT JOIN 
    PostHistoryDetails ph ON pp.PostId = ph.PostId
LEFT JOIN 
    ClosedPosts cp ON pp.PostId = cp.PostId
WHERE 
    up.PostCount > 5
ORDER BY 
    up.TotalScore DESC, up.TotalViews DESC;
