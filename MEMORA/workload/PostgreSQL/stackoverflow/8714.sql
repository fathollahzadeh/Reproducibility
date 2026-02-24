
WITH UserBadgeStats AS (
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
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ubs.DisplayName,
    ubs.BadgeCount,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges,
    upa.PostCount,
    upa.QuestionCount,
    upa.AnswerCount,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViewCount,
    pp.Score AS PopularPostScore
FROM 
    UserBadgeStats ubs
JOIN 
    UserPostActivity upa ON ubs.UserId = upa.UserId
LEFT JOIN 
    PopularPosts pp ON pp.Rank = 1
WHERE 
    ubs.BadgeCount > 0
ORDER BY 
    ubs.BadgeCount DESC, upa.PostCount DESC
LIMIT 10;
