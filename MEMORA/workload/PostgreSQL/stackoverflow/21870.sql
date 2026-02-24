
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        ph.UserId AS CloserUserId,
        ph.UserDisplayName AS CloserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
ProcessedVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    R.Id,
    R.Title,
    R.Score,
    (P.TotalUpVotes::FLOAT / NULLIF(P.TotalVotes, 0)) AS UpVoteRatio,
    U.UserId,
    U.PostCount,
    U.UpVotes,
    U.DownVotes,
    U.AvgViewCount,
    COALESCE(ch.CloseDate, NULL) AS LastClosedDate,
    COALESCE(ch.CloseReason, 'N/A') AS CloseReason,
    COALESCE(ch.CloserUserId, -1) AS CloserUserId,
    COALESCE(ch.CloserDisplayName, 'System') AS CloserDisplayName
FROM 
    RankedPosts R
JOIN 
    UserStats U ON R.OwnerUserId = U.UserId
LEFT JOIN 
    ProcessedVotes P ON R.Id = P.PostId
LEFT JOIN 
    ClosedPostHistory ch ON R.Id = ch.PostId
WHERE 
    R.ScoreRank <= 5
    AND U.PostCount > 0
    AND (UPPER(R.Title) LIKE '%SQL%' OR R.Score > 10)
ORDER BY 
    R.Score DESC, U.AvgViewCount DESC;
