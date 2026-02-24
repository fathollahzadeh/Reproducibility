
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 0) AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 YEAR') 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
), RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 MONTH')
    GROUP BY 
        b.UserId, b.Name
), ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(rb.BadgeCount, 0) AS RecentBadges, 
        (SELECT COUNT(*) 
         FROM Posts p 
         WHERE p.OwnerUserId = u.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.ViewCount, 
    rp.NetScore, 
    au.DisplayName, 
    au.RecentBadges, 
    au.PostsCount, 
    CASE 
        WHEN au.RecentBadges > 0 
        THEN 'Active Badge Holder' 
        ELSE 'Regular User' 
    END AS UserStatus
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.NetScore > 0 
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.NetScore DESC, au.RecentBadges DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
