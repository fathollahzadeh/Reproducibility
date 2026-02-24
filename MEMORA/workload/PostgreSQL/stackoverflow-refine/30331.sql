
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.CommentCount) AS TotalComments,
        SUM(p.Score) AS TotalScore,
        AVG(p.TotalBounty) AS AvgBounty
    FROM 
        Users u
    JOIN 
        RankedPosts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopRankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalComments,
        TotalScore,
        AvgBounty,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserRankings
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalComments,
    u.TotalScore,
    u.AvgBounty,
    CASE 
        WHEN u.UserRank <= 10 THEN 'Top Contributor'
        WHEN u.TotalComments > 50 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM 
    TopRankedUsers u
WHERE 
    u.UserRank <= 20 OR (u.TotalComments > 20 AND u.AvgBounty > 0)
ORDER BY 
    u.TotalScore DESC;
