WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
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
        TotalQuestions,
        TotalAnswers,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    EXTRACT(YEAR FROM age(tu.LastPostDate)) AS YearsSinceLastPost,
    CASE 
        WHEN tu.TotalQuestions > tu.TotalAnswers THEN 'Questions Dominant'
        WHEN tu.TotalAnswers > tu.TotalQuestions THEN 'Answers Dominant'
        ELSE 'Balanced'
    END AS PostTypeBalance,
    COALESCE((SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
              FROM PostHistory ph
              JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
              WHERE ph.UserId = tu.UserId), 'No Activity') AS RecentActivity
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
