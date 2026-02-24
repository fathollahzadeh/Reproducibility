WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpvoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS DownvoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM PostLinks pl 
            WHERE pl.PostId = p.Id AND pl.LinkTypeId = 3
        ), 0) AS DuplicateCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Tags,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        DuplicateCount,
        RANK() OVER (ORDER BY UpvoteCount DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.DuplicateCount,
    tp.Tags,
    CASE 
        WHEN tp.DuplicateCount > 0 THEN 'This post has been marked as a duplicate.'
        ELSE 'This post is not marked as a duplicate.'
    END AS DuplicateStatus
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10 
ORDER BY 
    tp.Rank;