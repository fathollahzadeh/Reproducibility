WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(Score) DESC) AS UserRank
    FROM RankedPosts
    WHERE rn <= 5
    GROUP BY OwnerDisplayName
)
SELECT 
    tu.OwnerDisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.UserRank,
    STRING_AGG(rp.Title, ', ') AS TopPosts
FROM TopUsers tu
JOIN RankedPosts rp ON tu.OwnerDisplayName = rp.OwnerDisplayName
WHERE tu.UserRank <= 10
GROUP BY tu.OwnerDisplayName, tu.PostCount, tu.TotalScore, tu.UserRank
ORDER BY tu.UserRank;