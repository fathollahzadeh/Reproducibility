
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  
    GROUP BY 
        ph.PostId
),
TopComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ph.LastEditDate,
        COALESCE(tc.TotalComments, 0) AS TotalComments,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAnalysis ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        TopComments tc ON rp.PostId = tc.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    OwnerDisplayName,
    EditCount,
    LastEditDate,
    TotalComments,
    CommentCount,
    ScoreCategory
FROM 
    CombinedData
WHERE 
    ScoreCategory = 'High Score' 
ORDER BY 
    CreationDate DESC;
