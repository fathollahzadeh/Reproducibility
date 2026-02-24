
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Owner,
        ViewCount,
        Score,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostsWithTag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
)
SELECT 
    tp.Title,
    tp.Owner,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    ts.TagName,
    ts.PostsWithTag
FROM 
    TopPosts tp
JOIN 
    TagStats ts ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Tags LIKE CONCAT('%', ts.TagName, '%')
          AND p.Id = tp.PostId
    )
ORDER BY 
    tp.Score DESC, 
    ts.PostsWithTag DESC;
