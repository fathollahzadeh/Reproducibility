
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        p.Tags,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation, p.Tags
),

TagStatistics AS (
    SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        AVG(pd.Score) AS AverageScore,
        AVG(pd.ViewCount) AS AverageViewCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(pd.Tags, ',')) AS tag ON true
    JOIN 
        Tags t ON TRIM(tag) = t.TagName
    GROUP BY 
        pd.Tags
),

TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Author,
        pd.AuthorReputation,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes,
        pd.Score,
        pd.ViewCount,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.CreationDate DESC) AS Rank
    FROM 
        PostDetails pd
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.AuthorReputation,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.Score,
    tp.ViewCount,
    ts.AverageScore,
    ts.AverageViewCount,
    CONCAT('{ "PostId": ', tp.PostId, ', "Title": "', tp.Title, '" }') AS JsonRepresentation
FROM 
    TopPosts tp
JOIN 
    TagStatistics ts ON TRUE 
WHERE 
    tp.Rank <= 10 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
