
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = r.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) AS DownVoteCount,
    CASE
        WHEN r.RankScore <= 5 THEN 'Top'
        WHEN r.RankScore BETWEEN 6 AND 15 THEN 'Middle'
        ELSE 'Low'
    END AS RankingCategory
FROM 
    RankedPosts r
WHERE 
    r.RankScore <= 15
GROUP BY 
    r.PostId, r.Title, r.Score, r.ViewCount, r.OwnerDisplayName, r.RankScore
ORDER BY 
    r.PostId, r.Score DESC, r.ViewCount DESC;
