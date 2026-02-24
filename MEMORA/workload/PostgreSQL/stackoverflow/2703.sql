WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score >= 0
),
PostSummary AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.TotalBounty) AS AverageBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank <= 3
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.PostCount,
    ps.TotalScore,
    ps.TotalComments,
    ps.AverageBounty
FROM 
    Users u
INNER JOIN 
    PostSummary ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    ps.TotalScore DESC, 
    ps.PostCount DESC
LIMIT 10;
