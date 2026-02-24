WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        v.PostId
),
AggregatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        CASE
            WHEN rp.Score - COALESCE(rv.DownVotes, 0) < 0 THEN 'Negative Engagement'
            WHEN rp.Score + COALESCE(rv.UpVotes, 0) <= 10 THEN 'Low Engagement'
            ELSE 'High Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.Score,
        ap.ViewCount,
        ap.UpVotes,
        ap.DownVotes,
        ap.EngagementLevel,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        AggregatedPosts ap
    LEFT JOIN 
        ClosedPosts cp ON ap.PostId = cp.PostId
)
SELECT 
    *,
    CASE
        WHEN EngagementLevel = 'High Engagement' AND CloseCount = 0 THEN 'Promote'
        WHEN EngagementLevel = 'Negative Engagement' AND CloseCount > 0 THEN 'Review'
        ELSE 'Neutral'
    END AS NextSteps
FROM 
    FinalResults
WHERE 
    UpVotes > DownVotes
ORDER BY 
    EngagementLevel DESC, Score DESC;