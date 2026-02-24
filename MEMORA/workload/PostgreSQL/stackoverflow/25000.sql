WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
        AND p.Score IS NOT NULL
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= '2023-01-01'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    COALESCE(pv.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pv.Downvotes, 0) AS TotalDownvotes,
    rp.Score,
    rp.CommentCount,
    rph.RevisionCount,
    CASE 
        WHEN rp.Score > 10 THEN 'Highly Scored'
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderately Scored'
        ELSE 'Low Scored'
    END AS ScoreCategory,
    CASE 
        WHEN rp.CommentCount > 0 THEN
            (SELECT STRING_AGG(c.Text, '; ') 
             FROM Comments c 
             WHERE c.PostId = rp.PostId 
             LIMIT 3) 
        ELSE 'No Comments'
    END AS RecentComments
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostHistoryStats rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 5 
    AND (rph.PostHistoryTypeId IS NULL OR rph.RevisionCount > 1)
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC;