WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
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
UserActivity AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.QuestionsCount,
        us.AnswersCount,
        us.TotalScore,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC) AS Rank,
        (SELECT COUNT(*) FROM Users) AS TotalUsers
    FROM 
        UserPostStats us
),
RankedUserActivity AS (
    SELECT 
        ua.*,
        CASE 
            WHEN ua.Rank <= 10 THEN 'Top Contributor'
            ELSE 'Regular Contributor'
        END AS ContributorType
    FROM 
        UserActivity ua
)
SELECT 
    rua.DisplayName,
    rua.PostCount,
    rua.QuestionsCount,
    rua.AnswersCount,
    rua.TotalScore,
    rua.GoldBadges,
    rua.SilverBadges,
    rua.BronzeBadges,
    rua.ContributorType,
    CAST(100.0 * rua.Rank / rua.TotalUsers AS DECIMAL(5, 2)) AS ContributionPercentage
FROM 
    RankedUserActivity rua
WHERE 
    rua.TotalScore > 0
ORDER BY 
    rua.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;