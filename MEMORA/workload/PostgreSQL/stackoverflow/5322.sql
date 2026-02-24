WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Tags, 
        CreationDate,
        ViewCount,
        AnswerCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
),
PostActivity AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    JOIN 
        TopPosts tp ON ph.PostId = tp.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Title,
    tp.Tags,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Score,
    tp.OwnerDisplayName,
    pa.FirstEditDate,
    pa.CloseCount,
    pa.ReopenCount,
    pa.DeleteCount
FROM 
    TopPosts tp
JOIN 
    PostActivity pa ON tp.PostId = pa.PostId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;