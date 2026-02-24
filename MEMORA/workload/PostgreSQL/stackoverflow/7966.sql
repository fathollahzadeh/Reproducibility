WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND rp.PostId IN (SELECT PostId FROM Votes v WHERE v.VoteTypeId = 2)
),
TopAnswers AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND rp.PostId IN (SELECT ParentId FROM Posts WHERE PostTypeId = 2)
),
TopPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        'Question' AS PostType,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount
    FROM 
        TopQuestions tp
    UNION ALL
    SELECT 
        ta.PostId,
        ta.Title,
        ta.OwnerDisplayName,
        'Answer' AS PostType,
        ta.CreationDate,
        ta.Score,
        ta.ViewCount
    FROM 
        TopAnswers ta
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.PostType,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;