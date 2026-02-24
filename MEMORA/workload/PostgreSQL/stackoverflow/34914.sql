
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.Rank, 
        rp.CommentCount, 
        rp.UpVotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
PostHistorySummary AS (
    SELECT 
        postId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        postId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.UpVotes,
    fp.DiscussionLevel,
    COALESCE(ph.EditCount, 0) AS NumberOfEdits,
    ph.LastEditedDate
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistorySummary ph ON fp.PostId = ph.postId
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC;
