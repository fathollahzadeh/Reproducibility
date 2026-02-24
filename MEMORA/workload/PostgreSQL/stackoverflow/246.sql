
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Rank'
        ELSE 'Other Rank'
    END AS PostRankCategory,
    pp.LastEditDate AS RecentlyEditedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts pp ON rp.PostId = pp.Id AND pp.LastEditDate >= CURRENT_DATE - INTERVAL '3 months'
WHERE 
    rp.UserViewRank <= 10 OR rp.AnswerCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50 OFFSET 0;
