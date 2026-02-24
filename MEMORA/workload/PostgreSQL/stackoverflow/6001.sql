
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopRankedPosts AS (
    SELECT 
        rp.*, 
        ph.EditCount, 
        ph.LastEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats ph ON rp.PostId = ph.PostId
    WHERE 
        rp.Rank <= 5 
)
SELECT 
    trp.PostId, 
    trp.Title, 
    trp.Score, 
    trp.ViewCount, 
    trp.AnswerCount, 
    trp.OwnerDisplayName, 
    trp.EditCount, 
    trp.LastEditDate
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.Score DESC, 
    trp.ViewCount DESC;
