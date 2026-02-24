WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ARRAY_AGG(DISTINCT tag.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        p.Id AS PostId,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL) AS tag ON tp.PostId = tag.PostId
GROUP BY 
    tp.Title, 
    tp.CreationDate, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.CommentCount, 
    u.DisplayName, 
    u.Reputation
ORDER BY 
    tp.UpVotes DESC, 
    tp.CommentCount DESC;