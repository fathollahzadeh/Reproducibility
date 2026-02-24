
WITH ActiveUsers AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
EnhancedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COALESCE(COUNT(c.Id), 0) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY p.Id, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT ep.*, au.DisplayName AS UserDisplayName
    FROM EnhancedPosts ep
    JOIN ActiveUsers au ON ep.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = au.Id
    )
)
SELECT rp.*, 
       (UpVotes - DownVotes) AS NetVotes,
       CASE 
           WHEN rp.CommentCount > 10 THEN 'Popular' 
           ELSE 'Less Popular' 
       END AS PopularityStatus
FROM RankedPosts rp
LEFT JOIN Badges b ON rp.PostId = b.UserId
WHERE (CASE 
           WHEN rp.CommentCount > 10 THEN 'Popular' 
           ELSE 'Less Popular' 
       END = 'Popular' OR (UpVotes - DownVotes) > 5)
  AND (b.Class = 1 OR b.Class = 2) 
ORDER BY NetVotes DESC, rp.CreationDate DESC
LIMIT 50;
