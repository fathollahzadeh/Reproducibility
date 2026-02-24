WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
), 
QuestionWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.Score,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.ViewCount, tp.CreationDate, tp.Score, tp.OwnerDisplayName
)
SELECT 
    qwc.PostId,
    qwc.Title,
    qwc.ViewCount,
    qwc.CreationDate,
    qwc.Score,
    qwc.OwnerDisplayName,
    CASE 
        WHEN qwc.CommentCount > 10 THEN 'Highly Engaged'
        WHEN qwc.CommentCount > 5 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    QuestionWithComments qwc
ORDER BY 
    qwc.ViewCount DESC 
LIMIT 10;