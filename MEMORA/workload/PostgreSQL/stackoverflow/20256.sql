
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
TagData AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2) AS Tags 
    FROM 
        Posts p
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    COALESCE(cp.UserDisplayName, 'N/A') AS ClosuredBy,
    CASE 
        WHEN COUNT(DISTINCT cp.PostId) > 0 THEN 'Yes'
        ELSE 'No'
    END AS IsClosed,
    STRING_AGG(td.Tags, ', ') AS AssociatedTags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount
FROM 
    RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN TagData td ON rp.PostId = td.PostId
LEFT JOIN Comments c ON rp.PostId = c.PostId
LEFT JOIN Votes v ON rp.PostId = v.PostId
WHERE 
    rp.PostRank = 1 
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.OwnerDisplayName, cp.UserDisplayName
HAVING 
    COUNT(c.Id) > 5 OR SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
