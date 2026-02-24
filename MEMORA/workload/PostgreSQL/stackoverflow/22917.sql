WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2020-01-01' 
        AND p.OwnerUserId IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgScore,
    us.MaxScore,
    us.MinScore,
    pp.PostRank,
    pp.Title,
    pc.CommentCount,
    COALESCE(pc.Comments, 'No comments') AS LatestComments
FROM 
    UserStatistics us
JOIN 
    Users u ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts pp ON pp.OwnerUserId = u.Id AND pp.PostRank = 1
LEFT JOIN 
    PostComments pc ON pc.PostId = pp.PostId
WHERE 
    us.TotalPosts > 5
    AND (us.MaxScore > 10 OR us.AvgScore > 5)
    AND EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = u.Id AND b.Class = 1
    )
ORDER BY 
    us.TotalPosts DESC, u.Reputation DESC;