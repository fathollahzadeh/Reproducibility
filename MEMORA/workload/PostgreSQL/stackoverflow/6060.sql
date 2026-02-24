
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostEngagement AS (
    SELECT 
        tp.Id, 
        tp.Title, 
        tp.OwnerDisplayName, 
        tp.Score, 
        tp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS UpvoteCount
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON tp.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) v ON tp.Id = v.PostId
)
SELECT 
    pe.Title, 
    pe.OwnerDisplayName, 
    pe.Score, 
    pe.ViewCount, 
    pe.CommentCount, 
    pe.UpvoteCount,
    (CAST(pe.ViewCount AS FLOAT) / NULLIF(pe.Score, 0)) AS ViewScoreRatio
FROM 
    PostEngagement pe
ORDER BY 
    pe.Score DESC, 
    pe.ViewCount DESC;
