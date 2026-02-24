WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.ViewCount) AS MaxViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pp.PostCount,
        pp.AverageScore,
        pp.QuestionCount,
        pp.AnswerCount,
        pp.MaxViewCount
    FROM 
        Users u
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        PopularPosts pp ON u.Id = pp.OwnerUserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostCount,
        AverageScore,
        QuestionCount,
        AnswerCount,
        MaxViewCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, AverageScore DESC) AS Rank
    FROM 
        UserPostMetrics
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    AverageScore,
    QuestionCount,
    AnswerCount,
    MaxViewCount
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
