
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
CommentsDetail AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.AvgViewCount,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    cd.CommentCount,
    cd.AllComments
FROM 
    UserPostStats u
LEFT JOIN 
    TopPosts tp ON u.UserId = tp.OwnerUserId AND tp.Rank <= 3
LEFT JOIN 
    CommentsDetail cd ON tp.PostId = cd.PostId
WHERE 
    u.TotalPosts > 5 OR u.TotalScore > 100
ORDER BY 
    u.TotalScore DESC, u.TotalPosts DESC;
