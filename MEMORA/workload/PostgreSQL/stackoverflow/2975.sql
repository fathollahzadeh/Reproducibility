
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN p.Score < 0 THEN p.Score ELSE 0 END) AS NegativeScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        PositiveScore,
        NegativeScore,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC, PositiveScore DESC) AS Rank
    FROM 
        UserActivity
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAcceptedAnswer,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.PositiveScore,
    tu.NegativeScore,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.IsAcceptedAnswer
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerUserId
WHERE 
    tu.Rank <= 10
    AND pd.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
ORDER BY 
    tu.TotalPosts DESC, tu.PositiveScore DESC;
