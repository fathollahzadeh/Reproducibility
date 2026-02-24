
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        PositivePosts,
        NegativePosts,
        HighViews,
        LastPostDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
TopPostTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.PositivePosts,
    tu.NegativePosts,
    tu.HighViews,
    tu.LastPostDate,
    tpt.TagName,
    tpt.PostCount AS TagPostCount,
    tpt.TotalViews,
    tpt.TotalScore
FROM 
    TopUsers tu
JOIN 
    TopPostTags tpt ON tu.PostCount > 0 AND tpt.TagRank <= 5
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, tpt.PostCount DESC;
