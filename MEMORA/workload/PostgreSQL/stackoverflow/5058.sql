
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE_TRUNC('year', '2024-10-01'::date) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.AuthorName,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.RankByComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByComments <= 10 
)
SELECT 
    trp.Title,
    trp.AuthorName,
    trp.CommentCount,
    trp.Upvotes,
    trp.Downvotes,
    CASE 
        WHEN p.PostTypeId = 1 THEN 'Question'
        WHEN p.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopRankedPosts trp
JOIN 
    Posts p ON trp.PostId = p.Id
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array
GROUP BY 
    trp.PostId, trp.Title, trp.AuthorName, trp.CommentCount, trp.Upvotes, trp.Downvotes, p.PostTypeId
ORDER BY 
    trp.CommentCount DESC, trp.Upvotes DESC;
