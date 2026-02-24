WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS rn,
        COUNT(*) OVER(PARTITION BY pt.Name) AS total_posts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score,
        (SELECT SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = rp.PostId) AS UpVotes,
        (SELECT SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = rp.PostId) AS DownVotes,
        NULLIF((SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId), 0) AS CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
Combined AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.UpVotes,
        fp.DownVotes,
        fp.CommentCount,
        CASE 
            WHEN fp.CommentCount IS NULL THEN 'No Comments'
            WHEN fp.CommentCount > 10 THEN 'Active Discussion'
            ELSE 'Few Comments'
        END AS CommentStatus
    FROM 
        FilteredPosts fp
)
SELECT 
    cb.Title,
    cb.CreationDate,
    cb.ViewCount,
    COALESCE(cb.UpVotes, 0) AS UpVotes,
    COALESCE(cb.DownVotes, 0) AS DownVotes,
    cb.CommentCount,
    cb.CommentStatus,
    CASE
        WHEN cb.Score IS NULL THEN 'No Score' 
        WHEN cb.Score > 100 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS PostRating
FROM 
    Combined cb
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cb.PostId)
WHERE 
    b.Id IS NULL OR b.Class < 3
ORDER BY 
    cb.Score DESC, 
    cb.ViewCount DESC
LIMIT 20;