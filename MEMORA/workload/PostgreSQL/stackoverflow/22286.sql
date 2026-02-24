WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR')
        AND p.Score IS NOT NULL
), 
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN v.UpVotes IS NOT NULL OR v.DownVotes IS NOT NULL THEN 
                (COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) 
            ELSE 
                0 
        END AS NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
    WHERE 
        rp.rn = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalAnalysis AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Score,
        pa.UpVotes,
        pa.DownVotes,
        pa.NetVotes,
        pa.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        PostAnalytics pa
    LEFT JOIN ClosedPosts cp ON pa.PostId = cp.PostId
)

SELECT 
    fa.PostId,
    fa.Title,
    fa.Score,
    fa.NetVotes,
    fa.CommentCount,
    fa.CloseCount,
    CASE 
        WHEN fa.CloseCount > 0 AND fa.Score < 0 THEN 'High Risk Post' 
        WHEN fa.NetVotes > 10 AND fa.CommentCount > 5 THEN 'Popular Post' 
        WHEN fa.NetVotes < -5 THEN 'Negative Feedback' 
        ELSE 'Average' 
    END AS PostCategory
FROM 
    FinalAnalysis fa
WHERE 
    (fa.CloseCount > 0 OR fa.CommentCount > 10)
    AND (fa.Score IS NOT NULL OR fa.Score < 0)
ORDER BY 
    fa.NetVotes DESC, 
    fa.CommentCount DESC
LIMIT 50;