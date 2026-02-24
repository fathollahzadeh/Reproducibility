
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY TagStats.TagCount ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id) AS AnswerCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 
             Id, 
             LENGTH(Tags) - LENGTH(REPLACE(Tags, '<>', '')) + 1 AS TagCount
         FROM 
             Posts
         WHERE 
             PostTypeId = 1) AS TagStats ON TagStats.Id = p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    rp.UpVoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         Id, 
         unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName 
     FROM 
         Posts) AS t ON t.Id = rp.PostId
WHERE 
    rp.Rank <= 10 
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.CommentCount, rp.AnswerCount, rp.UpVoteCount
ORDER BY 
    rp.Score DESC;
