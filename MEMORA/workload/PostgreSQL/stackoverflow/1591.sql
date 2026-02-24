
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.ViewCount,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBounty,
    us.Upvotes,
    us.AvgBounty 
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
WHERE 
    (rp.Rank <= 5 OR us.BadgeCount >= 3) 
    AND (p.AcceptedAnswerId IS NOT NULL OR p.AnswerCount > 0)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
