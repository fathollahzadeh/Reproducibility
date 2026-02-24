WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
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
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
AggregatedStats AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore,
        SUM(rp.AnswerCount) AS TotalAnswers
    FROM 
        PostTypes pt
    LEFT JOIN 
        RankedPosts rp ON pt.Id = rp.PostId
    GROUP BY 
        pt.Id, pt.Name
),
TopPosts AS (
    SELECT 
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0
)
SELECT 
    a.PostTypeName,
    a.TotalPosts,
    a.TotalViews,
    a.AverageScore,
    a.TotalAnswers,
    t.Title,
    t.Score,
    t.OwnerDisplayName
FROM 
    AggregatedStats a
LEFT JOIN 
    TopPosts t ON a.PostTypeId = t.ScoreRank
ORDER BY 
    a.TotalPosts DESC, a.AverageScore DESC;