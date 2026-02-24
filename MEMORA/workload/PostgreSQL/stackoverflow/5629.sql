WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rnk
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS TotalQuestions,
        AVG(rp.Score) AS AvgScore,
        AVG(rp.ViewCount) AS AvgViewCount,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rnk <= 5 
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    tp.TotalQuestions,
    tp.AvgScore,
    tp.AvgViewCount,
    tp.TotalAnswers,
    tp.TotalComments
FROM 
    Users u
LEFT JOIN 
    TopPosts tp ON u.DisplayName = tp.OwnerDisplayName
WHERE 
    u.Reputation > 1000 
ORDER BY 
    tp.AvgScore DESC, 
    tp.TotalQuestions DESC
LIMIT 10;