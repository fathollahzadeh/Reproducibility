WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, PostCount, TotalScore 
    FROM 
        UserPostStats
    WHERE 
        PostRank <= 10
),
CommentStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AverageCommentLength
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.AverageCommentLength, 0) AS AvgCommentLength,
    CASE 
        WHEN tu.TotalScore > 1000 THEN 'High'
        WHEN tu.TotalScore BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    TopUsers tu
LEFT JOIN 
    CommentStatistics cs ON tu.UserId = cs.OwnerUserId
ORDER BY 
    tu.PostCount DESC, tu.TotalScore DESC;