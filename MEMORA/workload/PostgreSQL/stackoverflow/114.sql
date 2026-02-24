
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
MaxPostUser AS (
    SELECT 
        UserId,
        TotalPosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts
    FROM 
        UserPostStats
    WHERE 
        UserId IN (SELECT UserId FROM MaxPostUser WHERE Rank <= 10)
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    CASE 
        WHEN ups.Questions > 0 THEN ROUND(ups.TotalBounty / ups.Questions, 2)
        ELSE 0
    END AS AvgBountyPerQuestion,
    p.Title AS LastPostTitle,
    p.CreationDate AS LastPostDate,
    p.ViewCount
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId 
    AND p.LastActivityDate = (SELECT MAX(LastActivityDate) FROM Posts WHERE OwnerUserId = tu.UserId)
LEFT JOIN 
    UserPostStats ups ON tu.UserId = ups.UserId
ORDER BY 
    tu.TotalPosts DESC, AvgBountyPerQuestion DESC;
