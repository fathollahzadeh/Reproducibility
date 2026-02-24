
WITH RecentUserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           u.Reputation, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           COUNT(DISTINCT c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    LEFT JOIN Comments c ON u.Id = c.UserId AND c.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName, u.Reputation
), TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           Reputation, 
           PostCount, 
           CommentCount, 
           UpVotes, 
           DownVotes
    FROM RecentUserActivity
    WHERE PostRank <= 10
)
SELECT t.UserId, 
       t.DisplayName, 
       t.Reputation, 
       t.PostCount, 
       t.CommentCount, 
       t.UpVotes, 
       t.DownVotes,
       (SELECT COUNT(*) FROM Badges b WHERE b.UserId = t.UserId) AS BadgeCount,
       (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
        FROM Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        WHERE p.OwnerUserId = t.UserId) AS PostTypes
FROM TopUsers t
ORDER BY t.Reputation DESC;
