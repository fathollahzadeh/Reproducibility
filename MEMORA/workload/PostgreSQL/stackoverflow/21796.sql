WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rw_user_creation_order
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
    GROUP BY 
        p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT COALESCE(pht.Name, 'Unknown'), ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LatestEdit
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostWithFurtherLinks AS (
    SELECT 
        p.PostId,
        ARRAY_AGG(DISTINCT pl.RelatedPostId) AS RelatedPosts
    FROM 
        PostLinks pl
    JOIN 
        RankedPosts p ON pl.PostId = p.PostId
    GROUP BY 
        p.PostId
),
FinalBenchmark AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        pws.HistoryCount,
        pws.HistoryTypes,
        pws.LatestEdit,
        COALESCE(ps.RelatedPosts, '{}') AS RelatedPosts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats pws ON rp.PostId = pws.PostId
    LEFT JOIN 
        PostWithFurtherLinks ps ON rp.PostId = ps.PostId
)
SELECT 
    *,
    CASE 
        WHEN UpVotes = DownVotes THEN 'Neutralized Interaction'
        WHEN UpVotes > DownVotes THEN 'Positive Engagement'
        WHEN UpVotes < DownVotes THEN 'Negative Engagement'
        ELSE 'No Engagement'
    END AS EngagementType,
    TRIM(BOTH ' ' FROM Title) AS CleanedTitle,
    CASE 
        WHEN HistoryCount > 10 THEN 'Highly Edited'
        WHEN HistoryCount BETWEEN 5 AND 10 THEN 'Moderately Edited'
        ELSE 'Rarely Edited' 
    END AS EditFrequency
FROM 
    FinalBenchmark
WHERE 
    ((ViewCount >= 100 AND Score >= 10) OR
    (ViewCount < 100 AND Score = 0) AND
    NOT EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = FinalBenchmark.PostId AND c.Score < 0
    ))
ORDER BY 
    EngagementType, LatestEdit DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;