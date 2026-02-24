
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.TagRank,
        rp.Tags,
        COUNT(rp.PostId) AS TotalQuestions,
        AVG(rp.Score) AS AverageScore,
        SUM(rp.ViewCount) AS TotalViews,
        MAX(rp.CreationDate) AS MostRecentPost
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.TagRank, rp.Tags
)
SELECT 
    ps.Tags,
    ps.TotalQuestions,
    ps.AverageScore,
    ps.TotalViews,
    ps.MostRecentPost,
    STRING_AGG(DISTINCT bh.Name, ', ') AS BadgeNames,
    STRING_AGG(DISTINCT v.Name, ', ') AS VoteTypes
FROM 
    PostStatistics ps
LEFT JOIN 
    Posts p ON p.Tags = ps.Tags
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
LEFT JOIN 
    VoteTypes v ON v.Id IN (SELECT VoteTypeId FROM Votes WHERE PostId = p.Id)
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id
WHERE 
    ps.TagRank = 1 
GROUP BY 
    ps.Tags, ps.TotalQuestions, ps.AverageScore, ps.TotalViews, ps.MostRecentPost
ORDER BY 
    ps.TotalQuestions DESC, ps.AverageScore DESC;
