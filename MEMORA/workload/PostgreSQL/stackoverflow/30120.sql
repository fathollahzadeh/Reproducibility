
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(pa.CloseCount, 0) AS CloseCount,
        COALESCE(pa.ReopenCount, 0) AS ReopenCount,
        (SELECT STRING_AGG(pt.TagName, ', ') 
         FROM PopularTags pt
         JOIN Posts p ON p.Tags LIKE '%' || pt.TagName || '%'
         WHERE p.Id = rp.PostId) AS PopularTags
    FROM 
        RankedPosts rp
    LEFT JOIN PostHistoryAggregates pa ON rp.PostId = pa.PostId
    WHERE 
        rp.RankByScore <= 10
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.CommentCount,
    fr.VoteCount,
    fr.CloseCount,
    fr.ReopenCount,
    COALESCE(fr.PopularTags, 'No tags') AS Tags
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
