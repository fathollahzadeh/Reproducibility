WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostSummary AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 100 THEN 'Highly Rated'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS RatingGroup,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Active Discussion'
            ELSE 'Minimal Discussion'
        END AS DiscussionStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.RatingGroup,
    ps.DiscussionStatus
FROM 
    PostSummary ps
WHERE 
    ps.Score IS NOT NULL 
    AND ps.CommentCount IS NOT NULL
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC 
LIMIT 10;