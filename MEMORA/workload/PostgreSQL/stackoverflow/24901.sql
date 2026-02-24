WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(v.VoteCount, 0) AS UpVotes,
        (CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount 
         FROM Votes 
         WHERE VoteTypeId = 2 
         GROUP BY PostId) v ON p.Id = v.PostId
    WHERE 
        p.ViewCount > 100 
        AND p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
),

SubqueryPostStats AS (
    SELECT 
        PostId,
        SUM(ViewCount) AS TotalViews,
        COUNT(CASE WHEN (CreationDate BETWEEN cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND cast('2024-10-01 12:34:56' as timestamp)) THEN 1 END) AS RecentActivityCount
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 6) THEN 1 ELSE 0 END) AS TitleTagEdit
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - interval '1 month'
    GROUP BY 
        ph.PostId, ph.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(s.TotalViews, 0) AS TotalViews,
    COALESCE(s.RecentActivityCount, 0) AS RecentActivities,
    ph.EditCount AS NumberOfEdits,
    ph.TitleTagEdit AS TitleOrTagEdited,
    CASE 
        WHEN rp.HasAcceptedAnswer = 'Yes' THEN 'Accepted' 
        ELSE 'Pending' 
    END AS AcceptanceStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    SubqueryPostStats s ON rp.PostId = s.PostId
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank <= 5 
    AND rp.HasAcceptedAnswer = 'No'
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;