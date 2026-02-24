
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        TotalScore, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStatistics
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    ph.PostHistoryTypeId,
    COUNT(ph.Id) AS HistoryCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON tu.UserId = ph.UserId
WHERE 
    tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.Questions, tu.Answers, tu.TotalScore, tu.GoldBadges, tu.SilverBadges, tu.BronzeBadges, ph.PostHistoryTypeId
ORDER BY 
    tu.TotalScore DESC, tu.UserId;
