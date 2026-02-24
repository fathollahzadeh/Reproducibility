WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostBadges AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ub.BadgeCount DESC, ps.TotalScore DESC) AS Rank
    FROM 
        UserBadges ub
    JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    Rank
FROM 
    UserPostBadges
WHERE 
    Rank <= 10
ORDER BY 
    BadgeCount DESC, TotalScore DESC;
