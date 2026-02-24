WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        QuestionCount, 
        AnswerCount, 
        AcceptedAnswerCount, 
        AvgPostScore, 
        TotalViews, 
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalViews DESC) AS Rank
    FROM UserStats
)
SELECT 
    Rank,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    AvgPostScore,
    TotalViews,
    TotalComments
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
