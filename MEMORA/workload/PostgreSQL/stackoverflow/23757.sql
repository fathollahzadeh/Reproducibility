WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownvoteCount,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        STRING_AGG(DISTINCT CONCAT(ph.Comment, ' (', pht.Name, ')'), ', ') AS HistoryComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.UserId
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        COALESCE(phd.HistoryComments, 'No history') AS EditHistory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryData phd ON rp.PostId = phd.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.AcceptedAnswerId,
    fp.OwnerUserId,
    fp.PostRank,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    fp.TotalVotes,
    fp.EditHistory,
    CASE 
        WHEN fp.Score > 10 THEN 'Highly Rated'
        WHEN fp.Score IS NULL THEN 'No Score'
        ELSE 'Moderately Rated'
    END AS RatingCategory,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = fp.PostId) AS ChildPostCount
FROM 
    FilteredPosts fp
WHERE 
    fp.CommentCount > 0 
    AND fp.PostRank <= 5
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;