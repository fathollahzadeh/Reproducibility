
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 0 THEN 1 ELSE 0 END) AS PostsWithViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        t.TagName,
        pt.Name AS PostType,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR')
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.TotalScore,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC) AS Rank
    FROM 
        UserStats us
    WHERE 
        us.PostCount > 5
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.TagName,
    pd.PostType
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerUserId
ORDER BY 
    tu.Rank, pd.ViewCount DESC
LIMIT 10;
