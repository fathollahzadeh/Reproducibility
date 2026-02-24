WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p2.AnswerCount, 0) AS AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) p2 ON p.Id = p2.ParentId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.RankScore,
    rp.RankViews,
    COUNT(ph.Id) AS HistoryCount,
    STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    rp.RankScore <= 5 OR rp.RankViews <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.AnswerCount, rp.RankScore, rp.RankViews
ORDER BY 
    rp.RankScore, rp.RankViews, rp.ViewCount DESC;