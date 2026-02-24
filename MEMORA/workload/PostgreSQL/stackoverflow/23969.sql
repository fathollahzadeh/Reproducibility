
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.*,
        pcl.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCloseReasons pcl ON rp.PostId = pcl.PostId
    WHERE 
        rp.Rank <= 5
),
PostSummary AS (
    SELECT
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COALESCE(tp.CloseReasons, 'No close reasons') AS CloseReasons,
        CASE 
            WHEN tp.CommentCount > 10 THEN 'High Engagement'
            WHEN tp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel,
        COALESCE(tp.UpVoteCount, 0) AS EffectiveUpVoteCount,
        CONCAT('Post: ', tp.Title, ' - Engagement Level: ', 
               CASE 
                   WHEN tp.CommentCount > 10 THEN 'High Engage' 
                   WHEN tp.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engage' 
                   ELSE 'Low Engage' 
               END) AS EngagementDescription
    FROM 
        TopPosts tp
),
FinalOutput AS (
    SELECT 
        *,
        CASE 
            WHEN LENGTH(CloseReasons) > 0 THEN 'Has Close Reasons'
            ELSE 'Is Not Closed'
        END AS PostStatus,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS FinalRank
    FROM 
        PostSummary
)

SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    CloseReasons,
    EngagementLevel,
    EffectiveUpVoteCount,
    EngagementDescription,
    PostStatus,
    FinalRank
FROM 
    FinalOutput
WHERE 
    PostStatus = 'Is Not Closed'
ORDER BY 
    FinalRank, Score DESC;
