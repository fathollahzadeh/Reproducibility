WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(NULLIF(rp.Score, 0), NULL) AS AdjustedScore,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent'
            ELSE 'Older Posts'
        END AS PostAgeCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Id,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AdjustedScore,
    fp.PostAgeCategory,
    COALESCE(phd.CloseCount, 0) AS TotalCloses,
    COALESCE(phd.ReopenCount, 0) AS TotalReopens,
    COALESCE(phd.DeleteCount, 0) AS TotalDeletes
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryData phd ON fp.Id = phd.PostId
ORDER BY 
    fp.AdjustedScore DESC,
    fp.CreationDate ASC;