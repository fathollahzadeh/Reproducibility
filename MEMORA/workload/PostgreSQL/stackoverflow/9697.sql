WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankRecent
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        OwnerDisplayName,
        RankScore,
        RankRecent
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10 OR RankRecent <= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.OwnerDisplayName,
        phs.EditCount,
        phs.LastEdited
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistorySummary phs ON tp.PostId = phs.PostId
)
SELECT 
    *,
    CASE 
        WHEN AnswerCount > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS Status
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;