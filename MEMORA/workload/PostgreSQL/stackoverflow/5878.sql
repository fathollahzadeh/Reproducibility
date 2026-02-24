
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           p.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), UserStats AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT p.Id) AS PostsCreated, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT rp.PostId, 
       rp.Title, 
       rp.CreationDate, 
       rp.Score, 
       rp.ViewCount, 
       us.UserId, 
       us.DisplayName, 
       us.PostsCreated, 
       us.UpVotesReceived, 
       us.DownVotesReceived
FROM RankedPosts rp
JOIN UserStats us ON rp.OwnerUserId = us.UserId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, us.UpVotesReceived DESC;
