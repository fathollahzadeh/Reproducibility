
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, p.Tags, pt.Name
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        LastActivityDate, 
        ViewCount, 
        Score, 
        CommentCount, 
        TagList
    FROM 
        RankedPosts 
    WHERE 
        RankByScore <= 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.TagList,
    u.DisplayName AS AuthorName,
    b.Name AS BadgeName, 
    b.Class AS BadgeClass
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= tp.CreationDate
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
