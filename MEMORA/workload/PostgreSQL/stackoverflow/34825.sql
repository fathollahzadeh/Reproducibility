WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentChange
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostCounts
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    COUNT(rph.PostId) AS RecentChangesCount,
    STRING_AGG(DISTINCT rph.Title, ', ') AS RecentTitles,
    CASE 
        WHEN tu.PostCount >= 10 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rph ON tu.UserId = rph.UserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.PostCount
ORDER BY 
    tu.PostCount DESC;