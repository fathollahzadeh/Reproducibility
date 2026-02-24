
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount
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
        PositivePostCount,
        NegativePostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostCounts
    WHERE 
        PostCount > 0
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
)

SELECT 
    tu.DisplayName,
    tu.PostCount AS TotalPosts,
    tu.PositivePostCount AS PostsWithPositiveScore,
    tu.NegativePostCount AS PostsWithNegativeScore,
    COUNT(rph.PostId) AS RecentEditsCount,
    MIN(rph.CreationDate) AS FirstRecentEditDate,
    MAX(rph.CreationDate) AS LastRecentEditDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rph ON tu.UserId = rph.UserId
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.PositivePostCount, tu.NegativePostCount, tu.UserRank
ORDER BY 
    tu.UserRank;
