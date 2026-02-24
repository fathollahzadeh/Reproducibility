
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
), AggregatedData AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AverageViewCount,
        AVG(AnswerCount) AS AverageAnswerCount
    FROM 
        Posts
    GROUP BY 
        PostTypeId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    r.CommentCount,
    r.OwnerDisplayName,
    a.PostCount,
    a.TotalScore,
    a.AverageViewCount,
    a.AverageAnswerCount
FROM 
    RankedPosts r
JOIN 
    AggregatedData a ON r.PostTypeId = a.PostTypeId
WHERE 
    r.Rank <= 5
ORDER BY 
    r.PostTypeId, r.Rank;
