WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS UniqueTags,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank,
        ROW_NUMBER() OVER (ORDER BY COUNT(a.Id) DESC) AS AnswerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName
), 

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason,
        ph.Text AS RevisionDetails
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
), 

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.OwnerName,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UniqueTags,
        COALESCE(cp.CloseReason, 'No Close Reason') AS CloseReason,
        COALESCE(cp.RevisionDetails, 'No Revision Details') AS RevisionDetails,
        CASE 
            WHEN rp.CommentRank <= 10 THEN 'Top Commented'
            WHEN rp.AnswerRank <= 10 THEN 'Top Answered'
            ELSE 'Moderate Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    PostId,
    OwnerName,
    Title,
    CreationDate,
    CommentCount,
    AnswerCount,
    ARRAY_TO_STRING(UniqueTags, ', ') AS Tags,
    CloseReason,
    RevisionDetails,
    ActivityLevel
FROM 
    PostMetrics
WHERE 
    CommentCount > 0 OR AnswerCount > 0
ORDER BY 
    CreationDate DESC, CommentCount DESC;