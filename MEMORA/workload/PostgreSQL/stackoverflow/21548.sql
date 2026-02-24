
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Upvotes,
        SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13, 14)
),
TaggedPosts AS (
    SELECT 
        p.Id AS TagPostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p 
    JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag ON TRUE
    JOIN 
        Tags t ON TRIM(tag) = t.TagName
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.RankByScore,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(ph.LastClosed, 'Never Closed') AS LastCloseComment,
    tp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         ph.PostId, 
         ph.Comment AS LastClosed,
         ph.CreationDate
     FROM 
         PostHistoryCTE ph 
     WHERE 
         ph.HistoryRank = 1 AND ph.PostHistoryTypeId = 10) ph ON rp.PostId = ph.PostId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.TagPostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
