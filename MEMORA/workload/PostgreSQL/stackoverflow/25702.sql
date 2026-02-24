
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        p.Body,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'  
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.Body
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.TagsArray
    FROM RankedPosts rp
    WHERE rp.TagRank = 1  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CreationDate,
    fp.TagsArray,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount  
FROM FilteredPosts fp
LEFT JOIN Comments c ON fp.PostId = c.PostId
LEFT JOIN Votes v ON fp.PostId = v.PostId
GROUP BY fp.PostId, fp.Title, fp.ViewCount, fp.CreationDate, fp.TagsArray
ORDER BY fp.ViewCount DESC
LIMIT 10;
