
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        u.DisplayName AS AuthorDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag_list ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_list
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
),
MostLikedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.Tags,
        pd.AnswerCount,
        pd.CommentCount,
        RANK() OVER (ORDER BY pd.Score DESC) AS RankByScore,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS RankByViews
    FROM 
        PostDetails pd
)
SELECT 
    mlp.PostId,
    mlp.Title,
    mlp.CreationDate,
    mlp.ViewCount,
    mlp.Score,
    mlp.Tags,
    mlp.AnswerCount,
    mlp.CommentCount,
    CASE 
        WHEN mlp.RankByScore <= 10 THEN 'Top Scored'
        WHEN mlp.RankByViews <= 10 THEN 'Top Viewed'
        ELSE 'Other'
    END AS PostCategory
FROM 
    MostLikedPosts mlp
WHERE 
    mlp.RankByScore <= 10 OR mlp.RankByViews <= 10
ORDER BY 
    mlp.Score DESC, mlp.ViewCount DESC;
