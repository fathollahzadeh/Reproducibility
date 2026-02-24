WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        AnswerCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
),
PostsWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.ViewCount, tp.Score, tp.AnswerCount, tp.OwnerDisplayName
),
FinalReport AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.Score > 10 THEN 'High Engagement'
            WHEN p.Score BETWEEN 5 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PostsWithComments p
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.Score,
    fr.AnswerCount,
    fr.CommentCount,
    fr.OwnerDisplayName,
    fr.EngagementLevel
FROM 
    FinalReport fr
ORDER BY 
    fr.ViewCount DESC, 
    fr.Score DESC;