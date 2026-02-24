WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        (CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer' 
            ELSE 'No Accepted Answer' 
        END) AS AnswerStatus
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(*) AS ChangeCount
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        rp.CommentCount,
        rp.TotalBounty,
        rp.AnswerStatus,
        phs.ChangeTypes,
        phs.FirstChangeDate,
        phs.LastChangeDate,
        phs.ChangeCount,
        CASE 
            WHEN phs.ChangeCount IS NULL THEN 'No Changes'
            WHEN phs.ChangeCount > 10 THEN 'Highly Active Post'
            ELSE 'Activity Moderate'
        END AS ActivityLevel,
        (EXTRACT(EPOCH FROM (COALESCE(phs.LastChangeDate, cast('2024-10-01 12:34:56' as timestamp)) - rp.CreationDate)) / 3600.0) AS HoursSinceCreation
    FROM RankedPosts rp
    LEFT JOIN PostHistorySummary phs ON rp.PostId = phs.PostId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.ViewCount,
    cd.Score,
    cd.RankScore,
    cd.CommentCount,
    cd.TotalBounty,
    cd.AnswerStatus,
    cd.ChangeTypes,
    cd.FirstChangeDate,
    cd.LastChangeDate,
    cd.ChangeCount,
    cd.ActivityLevel,
    cd.HoursSinceCreation,
    (CASE 
        WHEN cd.HoursSinceCreation < 24 THEN 'New Post'
        WHEN cd.HoursSinceCreation BETWEEN 24 AND 168 THEN 'Recent Post'
        ELSE 'Old Post'
    END) AS PostAge
FROM CombinedData cd
WHERE cd.RankScore <= 10
AND cd.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
ORDER BY cd.Score DESC, cd.CommentCount DESC;