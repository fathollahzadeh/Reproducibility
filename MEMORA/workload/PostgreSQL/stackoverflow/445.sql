
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(pc.CommentsCount, 0) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            c.PostId, 
            COUNT(c.Id) AS CommentsCount
        FROM 
            Comments c
        GROUP BY 
            c.PostId
    ) pc ON p.Id = pc.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    us.DisplayName AS UserName,
    COUNT(rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.Score) AS AvgPostScore,
    SUM(us.GoldBadges) AS TotalGoldBadges,
    SUM(us.SilverBadges) AS TotalSilverBadges,
    SUM(us.BronzeBadges) AS TotalBronzeBadges,
    COUNT(DISTINCT us.UserId) AS TotalUsers
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId = us.UserId
LEFT JOIN 
    VoteTypes vt ON vt.Id = (SELECT MAX(vt2.Id) FROM Votes v INNER JOIN VoteTypes vt2 ON v.VoteTypeId = vt2.Id WHERE v.PostId = rp.PostId)
WHERE 
    rp.RankScore <= 5
    AND (vt.Name IS NULL OR vt.Name NOT LIKE '%DownMod%')
GROUP BY 
    us.DisplayName
ORDER BY 
    TotalViews DESC, AvgPostScore DESC;
