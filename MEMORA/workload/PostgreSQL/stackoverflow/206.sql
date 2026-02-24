
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        AnswerCount, 
        QuestionCount, 
        TotalBounty,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserPostStats
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    COALESCE(u.PostCount, 0) AS PostCount, 
    COALESCE(u.AnswerCount, 0) AS AnswerCount, 
    COALESCE(u.QuestionCount, 0) AS QuestionCount, 
    COALESCE(u.TotalBounty, 0) AS TotalBounty,
    CASE 
        WHEN u.BountyRank <= 10 THEN 'Top Bounty Users'
        WHEN u.BountyRank IS NOT NULL THEN 'Other Bounty Users'
        ELSE 'No Bounty'
    END AS UserCategory
FROM TopUsers u
FULL OUTER JOIN Users us ON u.UserId = us.Id
WHERE us.Location IS NOT NULL OR us.WebsiteUrl IS NOT NULL
ORDER BY UserCategory, TotalBounty DESC, u.DisplayName;
