
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalQuestionScore,
        TotalAnswerScore,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name
),
TopRecentPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        PostTypeName,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS RecentRank
    FROM RecentPosts
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    trp.Title AS RecentPostTitle,
    trp.CreationDate AS RecentPostDate,
    trp.OwnerDisplayName,
    trp.PostTypeName,
    trp.CommentCount,
    ROW_NUMBER() OVER (PARTITION BY tu.UserId ORDER BY trp.CreationDate DESC) AS UserPostRank
FROM TopUsers tu
JOIN TopRecentPosts trp ON tu.DisplayName = trp.OwnerDisplayName
WHERE tu.Rank <= 10 AND trp.RecentRank <= 5
ORDER BY tu.Rank, trp.CreationDate DESC;
