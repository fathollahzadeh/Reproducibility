
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        GREATEST(COALESCE(up.VoteCount, 0), COALESCE(down.VoteCount, 0), 0) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) up ON p.Id = up.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) down ON p.Id = down.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Body, p.CreationDate, u.DisplayName, up.VoteCount, down.VoteCount
),
TopPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, CreationDate DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.Body,
    tp.CreationDate,
    tp.Author,
    tp.CommentCount,
    tp.Score
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10 
ORDER BY 
    tp.Score DESC, 
    tp.CommentCount DESC;
