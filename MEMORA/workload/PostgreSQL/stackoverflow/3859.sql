
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalBounties,
        us.UserRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 5
    ORDER BY 
        us.TotalBounties DESC
    LIMIT 10
)

SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBounties,
    COALESCE(ph.RevisionGUID, 'No History') AS RevisionGUID,
    COALESCE(ph.Comment, 'No Comments') AS LastComment
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON tu.UserId = ph.UserId AND ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE UserId = tu.UserId
    )
ORDER BY 
    tu.UserRank;
