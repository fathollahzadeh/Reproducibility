
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)

SELECT 
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(PH.EditCount, 0) AS EditCount,
    PT.Name AS PostTypeName
FROM 
    RankedPosts rp
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PostId
) PH ON rp.PostId = PH.PostId
JOIN 
    PostTypes PT ON rp.PostTypeId = PT.Id
WHERE 
    rp.Rank <= 5 
ORDER BY 
    PT.Name, rp.Rank;
