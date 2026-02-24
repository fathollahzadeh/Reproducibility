WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank = 1 AND rp.UpVoteCount >= 10 THEN 'Top Question'
            WHEN rp.Rank > 1 AND rp.UpVoteCount = 0 THEN 'Low Engagement Answer'
            ELSE 'Regular Post'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        CONCAT('Closed by: ', (SELECT STRING_AGG(DISTINCT u.DisplayName, ', ') 
                               FROM PostHistory ph2
                               JOIN Users u ON ph2.UserId = u.Id
                               WHERE ph2.PostId = ph.PostId AND ph2.PostHistoryTypeId = 10)) AS ClosedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.EngagementLevel,
    cp.ClosedBy
FROM 
    FilteredPosts fp
LEFT JOIN 
    ClosedPosts cp ON fp.PostId = cp.PostId
WHERE 
    (fp.Score > 10 OR cp.ClosedBy IS NOT NULL) 
ORDER BY 
    CASE 
        WHEN cp.ClosedBy IS NOT NULL THEN 1 
        ELSE 0 
    END DESC, 
    fp.CreationDate DESC
LIMIT 50;