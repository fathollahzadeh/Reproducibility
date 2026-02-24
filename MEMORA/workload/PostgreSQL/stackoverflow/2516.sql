
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), 

ClosedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        ph.CreationDate AS ClosedDate, 
        ph.Comment AS CloseReason 
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),

PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(*) AS PostCount
    FROM 
        Tags t 
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 10
)

SELECT 
    rp.Id AS PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    cp.ClosedDate,
    cp.CloseReason,
    pt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.ViewCount DESC NULLS LAST;
