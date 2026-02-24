
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        DATE_PART('year', DATE '2024-10-01') - DATE_PART('year', u.CreationDate) AS AccountAge
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounty,
        TotalScore,
        AccountAge
    FROM 
        UserActivity
    WHERE 
        Reputation > 1000 AND 
        PostCount > 0 AND 
        AccountAge > 1
)
SELECT 
    fu.DisplayName,
    fu.Reputation,
    fu.PostCount,
    fu.CommentCount,
    fu.TotalBounty,
    fu.TotalScore,
    ROUND((CAST(fu.TotalScore AS DECIMAL) / NULLIF(fu.PostCount, 0)), 2) AS AverageScorePerPost
FROM 
    FilteredUsers fu
ORDER BY 
    fu.TotalScore DESC,
    fu.Reputation DESC
LIMIT 10;
