WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.OwnerUserId, 
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.OwnerDisplayName, 
        COUNT(rp.Id) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        SUM(CASE WHEN rp.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN rp.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        ps.OwnerDisplayName, 
        ps.PostCount, 
        ps.AvgScore,
        PS.PositivePosts,
        ps.NegativePosts,
        ROW_NUMBER() OVER (ORDER BY ps.PostCount DESC) AS UserRank
    FROM 
        PostStats ps
)
SELECT 
    tu.OwnerDisplayName, 
    tu.PostCount, 
    tu.AvgScore,
    CASE 
        WHEN tu.PositivePosts > tu.NegativePosts THEN 'Positive Contributor'
        ELSE 'Negative Contributor' 
    END AS ContributorType
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.PostCount DESC;