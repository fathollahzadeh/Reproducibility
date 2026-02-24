
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 /* Considering only Questions */
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' /* Only questions created in the last year */
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS Downvotes,
    tp.Name AS PostTypeName,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
    AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) 
                           FROM PostHistory ph2 
                           WHERE ph2.PostId = rp.PostId AND ph2.PostHistoryTypeId IN (4, 5, 6) /* Filtering edit types */)
LEFT JOIN 
    PostTypes tp ON rp.Rank = 1 /* Just an example to demonstrate joining another table */
WHERE 
    rp.Rank <= 5 /* Retrieve top 5 most recent questions per location */
ORDER BY 
    rp.LastActivityDate DESC;
