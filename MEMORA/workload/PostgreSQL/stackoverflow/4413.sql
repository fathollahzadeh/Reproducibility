
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.Score IS NOT NULL
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(tc.CommentCount, 0) AS TotalComments,
        COALESCE(cp.CloseCount, 0) AS TotalCloseCount,
        CASE 
            WHEN COALESCE(cp.CloseCount, 0) > 0 THEN 'Closed' 
            ELSE 'Open' 
        END AS Status,
        rp.RankScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopComments tc ON rp.Id = tc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.TotalComments,
    pd.TotalCloseCount,
    pd.Status,
    (SELECT AVG(p.Score) FROM Posts p WHERE p.OwnerUserId = (SELECT p2.OwnerUserId FROM Posts p2 WHERE p2.Id = pd.PostId)) AS AvgOwnerScore
FROM 
    PostDetails pd
WHERE 
    pd.RankScore <= 5
ORDER BY 
    pd.TotalComments DESC, 
    pd.CreationDate ASC
LIMIT 10;
