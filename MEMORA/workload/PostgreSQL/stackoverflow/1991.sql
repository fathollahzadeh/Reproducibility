WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           u.Reputation AS OwnerReputation, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerReputation
    FROM RankedPosts rp
    WHERE rp.PostRank = 1
),
PostVoteSummary AS (
    SELECT pv.PostId, 
           COUNT(CASE WHEN pv.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
           COUNT(CASE WHEN pv.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes pv
    GROUP BY pv.PostId
)
SELECT fp.Id, 
       fp.Title, 
       fp.CreationDate, 
       fp.Score, 
       fp.ViewCount,
       COALESCE(pvs.UpVotes, 0) AS UpVotes,
       COALESCE(pvs.DownVotes, 0) AS DownVotes,
       CASE 
           WHEN fp.Score > 100 THEN 'Highly Scored'
           WHEN fp.Score BETWEEN 50 AND 100 THEN 'Moderately Scored'
           ELSE 'Low Scored' 
       END AS ScoreCategory
FROM FilteredPosts fp
LEFT JOIN PostVoteSummary pvs ON fp.Id = pvs.PostId
ORDER BY fp.CreationDate DESC
LIMIT 50;