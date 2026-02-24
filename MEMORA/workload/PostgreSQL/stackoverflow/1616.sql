
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    pd.TotalCommentScore,
    CASE 
        WHEN pd.TotalCommentScore > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS PostActivityStatus,
    CASE 
        WHEN ua.TotalBountyAmount > 100 THEN 'High Bounty Buyer'
        WHEN ua.TotalBountyAmount BETWEEN 50 AND 100 THEN 'Moderate Bounty Buyer'
        ELSE 'Low Bounty Buyer'
    END AS BountyBuyingStatus
FROM 
    UserActivity ua
INNER JOIN 
    RankedPosts rp ON ua.UserId = rp.PostId
INNER JOIN 
    PostDetails pd ON rp.PostId = pd.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    ua.PostCount DESC, pd.TotalCommentScore DESC;
