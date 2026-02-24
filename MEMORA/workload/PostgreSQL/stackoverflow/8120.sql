
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(p.Score) AS TotalScore,
           SUM(p.ViewCount) AS TotalViews,
           COUNT(DISTINCT p.Id) AS PostCount,
           RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT ru.DisplayName AS RecentAuthor,
       rp.Title,
       rp.CreationDate,
       rp.CommentCount,
       rp.UpVotes,
       rp.DownVotes,
       tu.DisplayName AS TopAuthor,
       tu.TotalScore,
       tu.TotalViews,
       tu.PostCount
FROM RankedPosts rp
JOIN Users ru ON rp.PostId = ru.Id
JOIN TopUsers tu ON tu.UserRank <= 10
WHERE rp.RecentPostRank = 1
ORDER BY rp.Score DESC, rp.CommentCount DESC
LIMIT 50;
