
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN p.PostTypeId = 1 AND ph.PostHistoryTypeId = 5 THEN 1 ELSE 0 END) AS EditedQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        ClosedPosts,
        EditedQuestions,
        Upvotes,
        Downvotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS RN
    FROM UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    ClosedPosts,
    EditedQuestions,
    Upvotes,
    Downvotes
FROM MostActiveUsers
WHERE RN <= 10;
