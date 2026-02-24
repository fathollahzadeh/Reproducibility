WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Body,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Body,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.Score > 0 
),
TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        RecentQuestions rp ON p.Id = rp.Id
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    ru.DisplayName,
    COUNT(DISTINCT r.Id) AS NumberOfPosts,
    SUM(r.Score) AS TotalScore,
    AVG(r.CommentCount) AS AverageComments,
    COALESCE(SUM(r.TotalBounty), 0) AS TotalBountyEarned
FROM 
    RecentQuestions r
JOIN 
    TopUsers ru ON r.OwnerUserId = ru.Id
GROUP BY 
    ru.DisplayName
ORDER BY 
    TotalScore DESC, NumberOfPosts DESC;