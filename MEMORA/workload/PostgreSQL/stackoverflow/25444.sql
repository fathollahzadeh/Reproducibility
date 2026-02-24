WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY STRING_AGG(t.TagName, ',') ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.ViewCount, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserVotes AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    u.DisplayName AS Owner,
    rp.ViewCount,
    rp.Score,
    cb.CloseDate,
    cb.ClosedBy,
    cb.CloseReason,
    uv.VoteCount,
    uv.UpVotes,
    uv.DownVotes,
    rp.TagRank
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    UserVotes uv ON rp.OwnerUserId = uv.OwnerUserId
WHERE 
    rp.TagRank = 1 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;