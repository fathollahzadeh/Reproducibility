
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        LEAD(p.LastActivityDate) OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate) AS NextActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(ph.Id) AS EditCount,
        p.OwnerUserId  -- Added to GROUP BY clause
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId, p.LastActivityDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(COALESCE(p.Score, 0)) AS MaxPostScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    WHERE 
        u.Reputation > 100 AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalBounties,
    COALESCE(rp.PostId, -2) AS TopPostId,
    u.AvgViewCount,
    u.MaxPostScore,
    CASE 
        WHEN u.PostCount = 0 THEN 'No Posts' 
        WHEN u.TotalBounties IS NULL THEN 'No Bounties' 
        ELSE 'Active User' 
    END AS UserStatus,
    CASE 
        WHEN rp.RankScore <= 3 THEN 'Top Contributor' 
        ELSE 'Regular Contributor' 
    END AS ContributorLevel
FROM 
    UserMetrics u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
WHERE 
    u.Reputation BETWEEN 100 AND 5000
ORDER BY 
    u.TotalBounties DESC NULLS LAST, 
    u.AvgViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
