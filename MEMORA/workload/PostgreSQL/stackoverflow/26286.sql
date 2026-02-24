
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.ViewCount, p.CreationDate, u.DisplayName, p.OwnerUserId, p.AcceptedAnswerId
),

TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.OwnerUserId,
        rp.AcceptedAnswerId,
        rp.CommentCount,
        STRING_AGG(t.TagName, ', ') AS FormattedTags
    FROM 
        RecentPosts rp
    LEFT JOIN 
        LATERAL (
            SELECT 
                TRIM(UNNEST(STRING_TO_ARRAY(rp.Tags, '><'))) AS TagName
        ) t ON TRUE
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.ViewCount, rp.CreationDate, rp.OwnerDisplayName, rp.OwnerUserId, rp.AcceptedAnswerId, rp.CommentCount
),

PostHistoryAggregated AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.Id) AS RevisionCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.FormattedTags,
    tp.ViewCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COALESCE(pha.HistoryTypes, 'No history') AS PostHistory,
    COALESCE(pha.RevisionCount, 0) AS RevisionCount,
    CASE 
        WHEN tp.CommentCount > 0 THEN 'Engaged'
        ELSE 'Not Engaged'
    END AS EngagementStatus
FROM 
    TaggedPosts tp
LEFT JOIN 
    PostHistoryAggregated pha ON tp.PostId = pha.PostId
ORDER BY 
    tp.ViewCount DESC,
    tp.CreationDate DESC
LIMIT 100;
