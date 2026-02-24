
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 10 
),
PostsWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName
),
FinalReport AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerDisplayName,
        p.CommentCount,
        CASE 
            WHEN p.Score >= 50 THEN 'High'
            WHEN p.Score BETWEEN 20 AND 49 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        PostsWithComments p
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.OwnerDisplayName,
    fr.CommentCount,
    fr.ScoreCategory,
    COUNT(v.Id) AS VoteCount
FROM 
    FinalReport fr
LEFT JOIN 
    Votes v ON fr.PostId = v.PostId
GROUP BY 
    fr.PostId, fr.Title, fr.CreationDate, fr.ViewCount, fr.Score, fr.OwnerDisplayName, fr.CommentCount, fr.ScoreCategory
ORDER BY 
    fr.Score DESC, fr.CommentCount DESC;
