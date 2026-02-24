
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN (SELECT unnest(string_to_array(p.Tags, '<>')) AS tag FROM Posts p) AS tag ON TRUE 
        JOIN Tags t ON tag = t.TagName
    WHERE 
        p.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year' 
        AND p.Score >= 10
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.PostRank,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.PostRank, rp.Score DESC;
