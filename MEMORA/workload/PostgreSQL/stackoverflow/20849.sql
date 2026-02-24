
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) AS UpvoteCount,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END) AS DownvoteCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Body, p.CreationDate
),
PostHistoryWithVotes AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS VoteCount,
        MAX(ph.CreationDate) AS MostRecentEdit
    FROM 
        PostHistory ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
QualifiedPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Author,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Edited' 
            ELSE 'Original' 
        END AS PostStatus,
        COALESCE(ph.VoteCount, 0) AS TotalVotes,
        ph.MostRecentEdit
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryWithVotes ph ON rp.PostID = ph.PostId 
    WHERE 
        rp.RankByType < 6
)
SELECT 
    qp.Author,
    qp.Title,
    qp.CommentCount,
    qp.UpvoteCount,
    qp.DownvoteCount,
    qp.PostStatus,
    qp.TotalVotes,
    qp.MostRecentEdit,
    CASE 
        WHEN qp.TotalVotes IS NULL THEN 'No votes'
        WHEN qp.TotalVotes > 0 THEN 'Positive feedback'
        ELSE 'Negative feedback'
    END AS FeedbackSentiment
FROM 
    QualifiedPosts qp
WHERE 
    qp.CommentCount > 5 OR (qp.TotalVotes > 10 AND qp.UpvoteCount > qp.DownvoteCount)
ORDER BY 
    qp.CommentCount DESC, qp.UpvoteCount DESC;
