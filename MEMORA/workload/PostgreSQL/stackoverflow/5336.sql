
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViewCount,
        COUNT(PostId) AS TotalPosts
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    TotalScore,
    TotalViewCount,
    TotalPosts,
    RANK() OVER (ORDER BY TotalScore DESC) AS Rank
FROM 
    TopUsers
WHERE 
    TotalPosts > 5
ORDER BY 
    Rank;
