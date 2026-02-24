
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
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.AnswerCount) AS AverageAnswers,
        AVG(rp.CommentCount) AS AverageComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        um.DisplayName,
        pm.TotalPosts,
        pm.TotalScore,
        pm.TotalViews,
        pm.AverageAnswers,
        pm.AverageComments,
        RANK() OVER (ORDER BY pm.TotalScore DESC) AS UserRank
    FROM 
        Users um
    JOIN 
        PostMetrics pm ON um.DisplayName = pm.OwnerDisplayName
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalScore,
    u.TotalViews,
    u.AverageAnswers,
    u.AverageComments,
    u.UserRank
FROM 
    TopUsers u
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank;
