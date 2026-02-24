
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        pt.Name AS PostType,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= DATE '2023-01-01' 
)

SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.PostType,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Tags,
    COUNT(ph.Id) AS HistoryCount
FROM
    RankedPosts rp
LEFT JOIN
    PostHistory ph ON rp.PostId = ph.PostId
GROUP BY
    rp.PostId, rp.Title, rp.Body, rp.PostType, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName, rp.Tags
HAVING
    MAX(rp.PostRank) <= 3 
ORDER BY
    rp.PostType,
    rp.Score DESC,
    rp.ViewCount DESC;
