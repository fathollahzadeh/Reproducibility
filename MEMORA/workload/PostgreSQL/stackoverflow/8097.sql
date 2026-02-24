
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        U.DisplayName AS Author, 
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount, 
        COUNT(DISTINCT v.UserId) AS VoteCount,
        PHT.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT v.UserId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    JOIN 
        PostHistory PHT ON p.Id = PHT.PostId AND PHT.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, U.DisplayName, PHT.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, Author, CommentCount, VoteCount, LastEditDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Author, 
    tp.CommentCount, 
    tp.VoteCount, 
    tp.LastEditDate, 
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagName, p.Id 
     FROM Posts p) AS tag_arr ON tp.PostId = tag_arr.Id
LEFT JOIN 
    Tags t ON t.TagName = tag_arr.TagName
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CommentCount, tp.VoteCount, tp.LastEditDate
ORDER BY 
    tp.VoteCount DESC, tp.CommentCount DESC;
