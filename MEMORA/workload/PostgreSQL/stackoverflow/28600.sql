
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 14) THEN 1 ELSE 0 END) AS UpVotes,    
        SUM(CASE WHEN v.VoteTypeId = 11 THEN 1 ELSE 0 END) AS DownVotes,       
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') AND
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL UNNEST(string_to_array(tp.Tags, '><')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    tp.UpVotes DESC;
