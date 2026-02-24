
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Only Questions */
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, 
        p.Score, p.ViewCount, u.DisplayName, p.AcceptedAnswerId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        CRT.Name AS CloseReason,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes CRT ON CAST(ph.Comment AS int) = CRT.Id
    WHERE 
        ph.PostHistoryTypeId = 10 /* Posts Closed */
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    STRING_AGG(DISTINCT rp.Tags, ', ') AS Tags,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.AcceptedAnswerId,
    rp.CommentCount,
    CASE 
        WHEN cp.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    cp.CloseReason,
    cp.UserDisplayName AS ClosureUser,
    cp.CreationDate AS ClosureDate,
    rp.PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5 /* Top 5 Posts per User */
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.LastActivityDate, 
    rp.Score, rp.ViewCount, rp.OwnerDisplayName, 
    rp.AcceptedAnswerId, rp.CommentCount, 
    cp.CloseReason, cp.UserDisplayName, cp.CreationDate, rp.PostRank
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
