
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS total_posts,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    (SELECT COUNT(*)
     FROM Comments c
     WHERE c.PostId = rp.Id) AS CommentCount,
    (SELECT STRING_AGG(CONCAT(u.DisplayName, ' - ', b.Name), ', ') 
     FROM Badges b
     JOIN Users u ON b.UserId = u.Id
     WHERE u.Id IN (SELECT DISTINCT OwnerUserId 
                    FROM Posts 
                    WHERE Id = rp.Id)
    ) AS UserBadges,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Upvoted'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Downvoted'
        ELSE 'No Votes'
    END AS VoteStatus,
    CASE 
        WHEN rp.total_posts > 1 THEN 'Multiple Entries'
        ELSE 'Single Entry'
    END AS PostMultiplicity
FROM RankedPosts rp
WHERE rp.rn = 1
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
