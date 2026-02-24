
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(AVG(c.Score), 0) AS AverageCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount, 
        MAX(ph.CreationDate) AS MostRecentCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.Rank,
        cp.CloseCount,
        cp.MostRecentCloseDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerName,
    CASE 
        WHEN pd.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN pd.Rank = 1 AND pd.CloseCount IS NOT NULL THEN 'Top Closed Post'
        WHEN pd.Rank = 1 THEN 'Top Active Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN pd.CloseCount > 5 AND pd.Score < 0 THEN 'High Close Rate with Low Score'
        ELSE 'Normal Activity'
    END AS ActivityDescription,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON t.TagName IS NOT NULL
WHERE 
    pd.Score >= 0 
    AND (pd.CloseCount IS NULL OR pd.CloseCount < 10)
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.Score, pd.ViewCount, pd.OwnerName, pd.CloseCount, pd.Rank
ORDER BY 
    pd.Score DESC, pd.CreationDate ASC
LIMIT 50;
