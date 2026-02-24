
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes vote ON vote.PostId = p.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
        WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionStatus,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'Cold'
    END AS PopularityStatus,
    (SELECT 
        COUNT(DISTINCT b.UserId) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
    ) AS UniqueBadgeCount,
    (SELECT STRING_AGG(DISTINCT lt.Name, ', ') 
     FROM LinkTypes lt 
     JOIN PostLinks pl ON pl.LinkTypeId = lt.Id 
     WHERE pl.PostId = rp.PostId
    ) AS RelatedPostTypes
FROM RankedPosts rp
WHERE rp.rn = 1
AND rp.Score IS NOT NULL
AND rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE ViewCount IS NOT NULL)
ORDER BY rp.Score DESC, rp.ViewCount DESC;
