WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Score, 
           p.CreationDate, 
           u.DisplayName AS OwnerDisplayName, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), PopularResponses AS (
    SELECT p.Id AS ResponseId, 
           p.ParentId, 
           p.Score AS ResponseScore, 
           u.DisplayName AS ResponderDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 2 AND p.Score > 0
), RecentVotes AS (
    SELECT v.PostId, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    WHERE v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY v.PostId
)
SELECT rp.PostId, 
       rp.Title, 
       rp.Score, 
       rp.Rank, 
       rp.OwnerDisplayName, 
       pr.ResponseId, 
       pr.ResponseScore, 
       pr.ResponderDisplayName, 
       rv.UpVotes, 
       rv.DownVotes
FROM RankedPosts rp
LEFT JOIN PopularResponses pr ON rp.PostId = pr.ParentId
LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC;