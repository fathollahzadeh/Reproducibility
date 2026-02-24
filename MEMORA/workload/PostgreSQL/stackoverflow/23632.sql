
WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.PopularPosts,
        ROW_NUMBER() OVER (ORDER BY ps.TotalPosts DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.PopularPosts,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    CASE
        WHEN tu.TotalPosts = 0 THEN 'No Posts'
        WHEN tu.TotalPosts > 100 THEN 'Super Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    STRING_AGG(p.Title, ', ') AS PopularPostTitles
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON p.OwnerUserId = tu.Id AND p.ViewCount > 100
GROUP BY 
    tu.DisplayName, tu.TotalPosts, tu.Questions, tu.Answers, tu.PopularPosts, tu.GoldBadges, tu.SilverBadges, tu.BronzeBadges
HAVING 
    COUNT(p.Id) = 0 
ORDER BY 
    tu.PopularPosts DESC;
