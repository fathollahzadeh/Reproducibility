
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
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '5 years'
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        AVG(rp.Score) AS AvgScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId IS NOT NULL
    GROUP BY 
        pt.Name
),
BadgeDistribution AS (
    SELECT 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Reputation
)
SELECT 
    ps.PostType,
    ps.AvgScore,
    ps.AvgViewCount,
    ps.TotalAnswers,
    ps.TotalComments,
    bd.Reputation,
    bd.BadgeCount
FROM 
    PostStatistics ps
JOIN 
    BadgeDistribution bd ON bd.Reputation > 0
ORDER BY 
    ps.AvgScore DESC, 
    ps.PostType;
