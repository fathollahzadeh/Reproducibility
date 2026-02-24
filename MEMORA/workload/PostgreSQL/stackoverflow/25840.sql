WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE((
            SELECT COUNT(v.Id)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2 
        ), 0) AS UpVotes,
        COALESCE((
            SELECT COUNT(v.Id)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3 
        ), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Title ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Author,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RowNum = 1 
),
PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    JOIN 
        (SELECT  
            Id, 
            unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName 
        FROM 
            Posts) t ON p.Id = t.Id 
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Author,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    pts.Tags,
    pts.RelatedPostCount
FROM 
    FilteredPosts fp
JOIN 
    PostTagStats pts ON fp.PostId = pts.PostId
ORDER BY 
    fp.CreationDate DESC, fp.Score DESC;