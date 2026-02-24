
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        TotalViews 
    FROM 
        UserPostStats 
    WHERE 
        UserRank <= 10
), 
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(c.Score), 0) AS MaxCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    pc.CommentCount,
    pc.MaxCommentScore,
    CASE 
        WHEN pc.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    TopUsers tu
LEFT JOIN 
    PostComments pc ON pc.PostId = (
        SELECT Id 
        FROM Posts 
        WHERE OwnerUserId = tu.UserId
        ORDER BY Id DESC 
        LIMIT 1
    )
ORDER BY 
    tu.TotalScore DESC;
