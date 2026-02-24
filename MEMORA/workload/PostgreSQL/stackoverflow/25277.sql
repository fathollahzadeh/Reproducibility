WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        RANK() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags, p.Score, b.Name
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Tags,
        Score,
        CommentCount,
        BadgeName
    FROM 
        RankedPosts
    WHERE 
        TagRank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Tags,
    fp.Score,
    fp.CommentCount,
    fp.BadgeName,
    STRING_AGG(c.Text, '; ') AS AllComments
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.Tags, fp.Score, fp.CommentCount, fp.BadgeName
ORDER BY 
    fp.CreationDate DESC
LIMIT 50;