
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),

MaxScores AS (
    SELECT 
        PostTypeId, 
        MAX(Score) AS MaxScore 
    FROM 
        Posts 
    GROUP BY 
        PostTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    ms.MaxScore,
    CASE 
        WHEN rp.Score = ms.MaxScore THEN 'Top Performance'
        ELSE 'Average Performance'
    END AS PerformanceStatus
FROM 
    RankedPosts rp
JOIN 
    MaxScores ms ON rp.PostTypeId = ms.PostTypeId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
