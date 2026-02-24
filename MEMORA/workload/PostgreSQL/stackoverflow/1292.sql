
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostLinksInfo AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(AVG(p.Score), 0) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    pb.BadgeCount,
    pb.GoldBadges,
    pli.LinkType,
    ua.TotalBounties,
    ua.AvgPostScore
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.Id = u.Id
LEFT JOIN 
    PostBadges pb ON u.Id = pb.UserId
LEFT JOIN 
    PostLinksInfo pli ON rp.Id = pli.PostId
JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    (pb.BadgeCount > 0 OR u.Reputation > 1000)
    AND (rp.RankScore <= 5 OR rp.RankViews <= 5)
ORDER BY 
    rp.Score DESC, 
    ua.TotalBounties DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
