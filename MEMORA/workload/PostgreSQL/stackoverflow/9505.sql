WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score > 0
),
PostHistorySummary AS (
    SELECT 
        p.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts p ON ph.PostId = p.PostId
    GROUP BY 
        p.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerReputation,
    COALESCE(pHS.EditCount, 0) AS EditCount,
    pHS.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary pHS ON rp.PostId = pHS.PostId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.PostId DESC;