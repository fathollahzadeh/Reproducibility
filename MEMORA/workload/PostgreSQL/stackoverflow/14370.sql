WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.Id, 0)) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        QuestionCount,
        AnswerCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    QuestionCount,
    AnswerCount,
    CommentCount,
    ViewRank
FROM TopUsers
WHERE ViewRank <= 10;