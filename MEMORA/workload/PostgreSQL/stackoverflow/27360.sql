
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        STRING_AGG(CONCAT(U.DisplayName, ' (', p.Title, ')'), '; ') AS UserContributions
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Tags, p.Title, p.CreationDate, p.ViewCount, p.Score, U.DisplayName
),
TagStatistics AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
    GROUP BY 
        Tags
)
SELECT 
    ts.Tags,
    ts.QuestionCount,
    ts.TotalViews,
    ts.AvgScore,
    rp.UserContributions
FROM 
    TagStatistics ts
LEFT JOIN 
    (SELECT Tags, UserContributions FROM RankedPosts WHERE RankByScore <= 5) rp ON ts.Tags = rp.Tags
ORDER BY 
    ts.AvgScore DESC, ts.TotalViews DESC;
