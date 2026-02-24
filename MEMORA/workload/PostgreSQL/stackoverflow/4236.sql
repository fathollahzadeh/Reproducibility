WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank,
        COALESCE(u.Location, 'Not specified') AS UserLocation,
        CASE 
            WHEN p.Score > 100 THEN 'Hot'
            WHEN p.Score BETWEEN 50 AND 100 THEN 'Warm'
            ELSE 'Cold'
        END AS ScoreCategory
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserLocation,
    rp.ScoreCategory,
    COALESCE(ph.Comment, 'No comments') AS LastEditComment,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS NumberOfComments,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId 
    AND ph.PostHistoryTypeId IN (4, 5) 
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
WHERE 
    rp.PostRank = 1
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.UserLocation, rp.ScoreCategory, ph.Comment
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 10;