
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        ViewCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        ViewRank,
        CommentRank
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10 OR CommentRank <= 10
),
TagStatistics AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        TopPosts
    GROUP BY 
        TagName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    ts.TagName,
    ts.PostCount
FROM 
    TopPosts tp
JOIN 
    TagStatistics ts ON tp.Tags LIKE '%' || ts.TagName || '%'
ORDER BY 
    tp.ViewCount DESC, 
    tp.CommentCount DESC;
