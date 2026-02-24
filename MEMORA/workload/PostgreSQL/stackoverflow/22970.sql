
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            WHEN p.PostTypeId = 3 THEN 'Wiki'
            ELSE 'Other'
        END AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId, 
        p.OwnerUserId, u.Id, u.Reputation, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post'
            WHEN rp.Rank <= 3 THEN 'High Performer'
            ELSE 'Regular Post'
        END AS PostClassification
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserReputation > 50 AND 
        rp.CommentCount > 5         
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditsCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.PostType,
    fp.PostClassification,
    pha.LastClosedDate,
    pha.SuggestedEditsCount,
    pht.Name AS LastPostHistoryType
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryAggregates pha ON fp.PostId = pha.PostId
LEFT JOIN 
    PostHistoryTypes pht ON pht.Id = (
        SELECT 
            ph.PostHistoryTypeId 
        FROM 
            PostHistory ph 
        WHERE 
            ph.PostId = fp.PostId 
        ORDER BY 
            ph.CreationDate DESC 
        LIMIT 1
    )
WHERE 
    fp.PostType IN ('Question', 'Answer')
ORDER BY 
    fp.Score DESC, 
    fp.UserReputation DESC
OFFSET 0 ROW FETCH NEXT 50 ROWS ONLY;
