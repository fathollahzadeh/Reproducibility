WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        WikiCount,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY AvgScore DESC) AS RankByScore
    FROM 
        UserPostStats
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserRankings AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.TotalPosts,
        tu.QuestionCount,
        tu.AnswerCount,
        tu.WikiCount,
        tu.AvgViewCount,
        tu.AvgScore,
        COALESCE(bs.TotalBadges, 0) AS TotalBadges,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY tu.RankByPosts, tu.RankByScore DESC) AS OverallRanking
    FROM 
        TopUsers tu
    LEFT JOIN 
        BadgeStats bs ON tu.UserId = bs.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    WikiCount,
    AvgViewCount,
    AvgScore,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    OverallRanking
FROM 
    UserRankings
WHERE 
    TotalPosts > 0
ORDER BY 
    OverallRanking
LIMIT 10;
