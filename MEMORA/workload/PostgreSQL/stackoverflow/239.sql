WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId), 0) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE 
        rp.Rank <= 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.ViewCount,
        fp.OwnerDisplayName,
        fp.AnswerStatus,
        fp.CommentCount,
        COALESCE(ps.EditCount, 0) AS EditCount,
        ps.HistoryTypes
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryStats ps ON fp.PostId = ps.PostId
)
SELECT 
    *,
    CASE 
        WHEN EditCount > 5 THEN 'Highly Edited'
        WHEN EditCount BETWEEN 3 AND 5 THEN 'Moderately Edited'
        ELSE 'Few Edits'
    END AS EditClassification
FROM 
    FinalResults
WHERE 
    Score >= 10 OR CommentCount > 5
ORDER BY 
    Score DESC, ViewCount ASC;