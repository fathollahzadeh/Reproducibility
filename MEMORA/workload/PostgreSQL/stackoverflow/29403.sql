
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopActiveUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        TotalGoldBadges,
        TotalSilverBadges,
        TotalBronzeBadges,
        RANK() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserActivity
),
UserResults AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        tu.TotalPosts,
        tu.TotalQuestions,
        tu.TotalAnswers,
        tu.TotalComments,
        tu.TotalUpVotes,
        tu.TotalDownVotes,
        tu.TotalGoldBadges,
        tu.TotalSilverBadges,
        tu.TotalBronzeBadges
    FROM 
        TopActiveUsers tu
    JOIN 
        Users u ON tu.UserId = u.Id
    WHERE 
        tu.UserRank <= 10
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges,
    CONCAT('Total Activity Score: ', 
           (TotalPosts + TotalAnswers * 2 + TotalUpVotes * 3 - TotalDownVotes * 1 + TotalGoldBadges * 10 + TotalSilverBadges * 5 + TotalBronzeBadges * 2)) AS ActivityScore
FROM 
    UserResults
ORDER BY 
    ActivityScore DESC;
