
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.PostTypeId
),

AggregatedByTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
),

PostWithTopTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        a.Tag
    FROM 
        RankedPosts rp
    JOIN 
        AggregatedByTags a ON rp.Title LIKE '%' || a.Tag || '%'
    WHERE 
        rp.Rank <= 10 
)

SELECT 
    p.PostId,
    p.Title,
    p.Author,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    STRING_AGG(p.Tag, ', ') AS Tags
FROM 
    PostWithTopTags p
GROUP BY 
    p.PostId, p.Title, p.Author, p.CommentCount, p.UpVotes, p.DownVotes
ORDER BY 
    p.UpVotes DESC, p.CommentCount DESC;
