WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.Score IS NOT NULL
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        COALESCE(NULLIF(rp.Upvotes - rp.Downvotes, 0), NULL) AS EngagementScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.Score,
    pe.ViewCount,
    pe.Upvotes,
    pe.Downvotes,
    pe.EngagementScore,
    COALESCE(phd.EditCount, 0) AS TotalEdits,
    COALESCE(phd.LastEditDate, NULL) AS LastEdit,
    COALESCE(phd.HistoryTypes, 'No History') AS ChangeHistory,
    CASE 
        WHEN pe.EngagementScore IS NULL THEN 'No Engagement'
        WHEN pe.EngagementScore > 0 THEN 'Positive Engagement'
        ELSE 'Negative Engagement'
    END AS EngagementStatus
FROM 
    PostEngagement pe
LEFT JOIN 
    PostHistoryDetails phd ON pe.PostId = phd.PostId
WHERE 
    pe.ViewCount > (SELECT AVG(ViewCount) FROM Posts) OR pe.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    pe.EngagementScore DESC, pe.CreationDate DESC
FETCH FIRST 20 ROWS ONLY;