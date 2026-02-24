
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopRecentPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RowNum = 1
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.CreationDate,
    trp.OwnerDisplayName,
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryChangeCount
FROM 
    TopRecentPosts trp
LEFT JOIN 
    PostHistory ph ON trp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
GROUP BY 
    trp.PostId, trp.Title, trp.Score, trp.CreationDate, trp.OwnerDisplayName, pht.Name
ORDER BY 
    trp.Score DESC, HistoryChangeCount DESC
LIMIT 10;
