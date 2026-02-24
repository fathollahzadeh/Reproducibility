WITH RECURSIVE PopularUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000

    UNION ALL

    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        pu.Level + 1
    FROM 
        Users u
    JOIN 
        PopularUsers pu ON u.Id = (SELECT UserId FROM Votes WHERE PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = pu.Id) LIMIT 1)
    WHERE 
        pu.Level < 3
),

UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CommentCount) AS AvgComments
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(bs.GoldCount, 0) AS GoldBadges,
    COALESCE(bs.SilverCount, 0) AS SilverBadges,
    COALESCE(bs.BronzeCount, 0) AS BronzeBadges,
    ps.PostCount,
    ps.PositivePosts,
    ps.TotalViews,
    ps.AvgComments,
    pu.Level AS PopularityLevel,
    CASE 
        WHEN ps.PostCount >= 10 THEN 'Active User'
        WHEN ps.PostCount < 10 AND ps.TotalViews > 1000 THEN 'Emerging User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    Users u
LEFT JOIN 
    UserBadges bs ON u.Id = bs.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    PopularUsers pu ON u.Id = pu.Id
WHERE 
    u.Reputation IS NOT NULL
ORDER BY 
    u.Reputation DESC,
    UserId
FETCH FIRST 50 ROWS ONLY;
