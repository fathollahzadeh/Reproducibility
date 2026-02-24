
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        AnswerCount,
        ViewCount,
        OwnerUserId,
        OwnerDisplayName,
        RankByScore,
        RankByDate
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 OR RankByDate <= 5
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResult AS (
    SELECT 
        tp.*,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.AnswerCount,
    fr.ViewCount,
    fr.OwnerDisplayName,
    fr.TotalComments,
    pt.Name AS PostType
FROM 
    FinalResult fr
JOIN 
    PostTypes pt ON fr.OwnerUserId = pt.Id
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC
LIMIT 50;
