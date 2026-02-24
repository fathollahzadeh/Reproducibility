WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TagStatistics AS (
    SELECT 
        TRIM(t.TagName) AS TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
CloseReasonsAnalysis AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS int) = c.Id  
    GROUP BY 
        p.Id
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ts.TagName,
        ts.PostCount AS RelatedPostsCount,
        ts.PositiveScoreCount,
        ts.AverageScore,
        cra.CloseReasonCount,
        cra.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagStatistics ts ON rp.PostId = ts.PostCount
    LEFT JOIN 
        CloseReasonsAnalysis cra ON rp.PostId = cra.PostId
    WHERE 
        rp.RankByScore <= 5  
)
SELECT 
    PostId,
    Title,
    Author,
    CreationDate,
    ViewCount,
    Score,
    TagName,
    RelatedPostsCount,
    PositiveScoreCount,
    AverageScore,
    CloseReasonCount,
    CloseReasons
FROM 
    PostSummary
ORDER BY 
    ViewCount DESC, Score DESC;