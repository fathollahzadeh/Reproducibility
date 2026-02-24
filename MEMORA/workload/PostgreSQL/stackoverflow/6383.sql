
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
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
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.FavoriteCount,
    r.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    pt.Name AS PostType,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    RankedPosts r
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
LEFT JOIN 
    PostTypes pt ON r.PostId = pt.Id
LEFT JOIN 
    PostLinks pl ON r.PostId = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
WHERE 
    r.Rank <= 10
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount, r.AnswerCount, r.CommentCount, r.FavoriteCount, r.OwnerDisplayName, pt.Name
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
