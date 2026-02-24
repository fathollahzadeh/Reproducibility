
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Tags, p.CreationDate
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Author,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn <= 5  
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.CreationDate,
    tp.Author,
    tp.CommentCount,
    tp.VoteCount,
    STRING_AGG(b.Name, ', ' ORDER BY b.Name) AS Badges,
    COALESCE((SELECT STRING_AGG(c.Text, ' | ' ORDER BY c.CreationDate) 
              FROM Comments c 
              WHERE c.PostId = tp.PostId), 'No comments') AS LatestComments
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.Tags, tp.CreationDate, tp.Author, tp.CommentCount, tp.VoteCount
ORDER BY 
    tp.CreationDate DESC;
