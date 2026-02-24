
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagName) AS t ON TRUE
    GROUP BY 
        p.Id, pt.Name, p.Title, p.Score, p.ViewCount, p.CreationDate
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.Rank,
    rp.TagsArray,
    COALESCE(cp.ClosedDate, NULL) AS ClosedDate,
    COALESCE(cp.UserDisplayName, 'Not Closed') AS ClosedBy,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
    pa.UpVotes,
    pa.DownVotes,
    pa.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostDetails cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    (rp.Rank <= 3 AND rp.Score > 0)  
    OR (cp.CloseCount > 1)           
ORDER BY 
    rp.CreationDate DESC;
