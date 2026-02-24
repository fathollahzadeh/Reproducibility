WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        CommentCount,
        Tags,
        ViewRank,
        ScoreRank
    FROM 
        RankedPosts 
    WHERE 
        ViewRank <= 10 OR ScoreRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Tags,
    CASE 
        WHEN tp.ViewRank <= 10 THEN 'Top Viewed'
        WHEN tp.ScoreRank <= 10 THEN 'Top Scored'
    END AS BenchmarkCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewRank, tp.ScoreRank;