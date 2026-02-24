
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId IN (3, 4, 5, 7) THEN 1 ELSE 0 END), 0) AS WikiCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS Rank
    FROM 
        UserPostStats
),
TopComments AS (
    SELECT 
        UserId,
        COUNT(*) AS CommentTotal
    FROM 
        Comments
    GROUP BY 
        UserId
)

SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    COALESCE(tc.CommentTotal, 0) AS TotalComments
FROM 
    TopUsers tu
LEFT JOIN 
    TopComments tc ON tu.UserId = tc.UserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
