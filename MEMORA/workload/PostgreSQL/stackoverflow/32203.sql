
WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), 
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(p.Score) OVER (PARTITION BY p.OwnerUserId) AS AvgScoreByUser,
        p.OwnerUserId,
        p.CreationDate,
        pt.Name AS PostTypeName
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, pt.Name
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ur.Id,
        ur.DisplayName,
        ur.Reputation,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM UserReputation ur
    LEFT JOIN UserPosts up ON ur.Id = up.UserId
    WHERE ur.Reputation IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.AvgScoreByUser,
    pa.PostTypeName
FROM TopUsers tu
LEFT JOIN PostAnalytics pa ON tu.Id = pa.OwnerUserId
WHERE tu.Rank <= 10
ORDER BY tu.Reputation DESC, pa.UpVoteCount DESC
