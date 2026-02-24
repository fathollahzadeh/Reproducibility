
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Ranking,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.AcceptedQuestions,
        us.TotalViews,
        us.TotalScore,
        DENSE_RANK() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName AS "User",
    COUNT(rp.PostId) AS "Recent Questions",
    SUM(rp.ViewCount) AS "Recent Views",
    MAX(rp.CreationDate) AS "Last Question Date",
    tu.TotalQuestions,
    tu.AcceptedQuestions,
    tu.TotalViews,
    tu.TotalScore,
    tu.UserRank
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
GROUP BY 
    tu.DisplayName, tu.TotalQuestions, tu.AcceptedQuestions, tu.TotalViews, tu.TotalScore, tu.UserRank
ORDER BY 
    tu.UserRank, "Recent Questions" DESC
LIMIT 10;
