
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) FROM Votes v WHERE v.PostId = p.Id), 0) AS VoteBalance
    FROM 
        Posts p
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.VoteBalance,
    CASE 
        WHEN rp.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') THEN 'Old Post' 
        ELSE 'Recent Post' 
    END AS PostAge,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    LATERAL (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName) AS t ON true
WHERE 
    rp.rn <= 5 AND 
    (rp.Score > 0 OR rp.CommentCount > 5)
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.VoteBalance, PostAge
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
