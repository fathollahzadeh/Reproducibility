
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
FilteredUserActivity AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        PostCount,
        TotalViews,
        TotalBounties,
        PostRank
    FROM 
        RecursiveUserActivity
    WHERE 
        PostCount > 5 
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalViews,
        TotalBounties, 
        PostRank,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY TotalViews DESC) AS ViewsRank
    FROM 
        FilteredUserActivity
    WHERE 
        Reputation >= 1000 
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    fa.PostCount,
    fa.TotalViews,
    fa.TotalBounties,
    CASE 
        WHEN u.ViewsRank <= 5 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopActiveUsers u
JOIN 
    FilteredUserActivity fa ON u.UserId = fa.UserId
WHERE 
    EXISTS (
        SELECT 1 
        FROM Badges b 
        WHERE b.UserId = u.UserId AND b.Class = 1 
    )
ORDER BY 
    u.Reputation DESC, 
    u.TotalViews DESC;
