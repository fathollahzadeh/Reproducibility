WITH UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           COALESCE(COUNT(c.Id), 0) AS CommentCount,
           COALESCE(MAX(ph.CreationDate), '1970-01-01') AS LastHistoryChange
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT ua.*, 
           PERCENT_RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserActivity ua
    WHERE ua.Rank = 1
)
SELECT u.UserId, 
       u.DisplayName, 
       u.QuestionCount, 
       u.AnswerCount, 
       u.TotalBounty, 
       p.PostId, 
       p.Title, 
       p.CreationDate AS PostCreationDate, 
       p.Score,
       p.ViewCount, 
       p.CommentCount,
       CASE 
           WHEN p.LastHistoryChange = '1970-01-01' THEN 'No Changes'
           ELSE 'Recently Edited'
       END AS PostStatus,
       COALESCE(t.BountyRank, 0) AS UserBountyRank
FROM TopUsers u
JOIN PostStats p ON u.UserId = p.PostId
LEFT JOIN TopUsers t ON u.UserId = t.UserId
ORDER BY u.TotalBounty DESC, p.Score DESC;