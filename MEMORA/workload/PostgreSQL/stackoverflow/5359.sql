
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerName,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.ViewCount,
    tp.Score,
    tp.UpVotes,
    tp.DownVotes,
    tp.AnswerCount,
    tp.CommentCount,
    COUNT(c.Id) AS TotalComments,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    (SELECT p.Id, STRING_AGG(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>') AS tag_list 
     FROM Posts p GROUP BY p.Id) AS tag_list ON tag_list.Id = tp.PostId
LEFT JOIN 
    Tags t ON t.TagName = ANY(STRING_TO_ARRAY(tag_list.tag_list, '><'))
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerName, tp.ViewCount, tp.Score, tp.UpVotes, tp.DownVotes, tp.AnswerCount, tp.CommentCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
