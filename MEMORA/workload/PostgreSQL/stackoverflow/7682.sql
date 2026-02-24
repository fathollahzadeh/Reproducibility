WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.PostID) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        AVG(rp.AnswerCount) AS AvgAnswerCount,
        AVG(rp.CommentCount) AS AvgCommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AvgViewCount,
    ps.AvgAnswerCount,
    ps.AvgCommentCount,
    ROW_NUMBER() OVER (ORDER BY ps.TotalScore DESC) AS Rank
FROM 
    PostSummary ps
ORDER BY 
    ps.TotalScore DESC
LIMIT 10;