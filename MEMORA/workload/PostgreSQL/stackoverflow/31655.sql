
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment = CAST(ctr.Id AS text) 
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostRankings AS (
    SELECT 
        pa.OwnerUserId AS UserId,
        SUM(pa.Score) AS TotalScore,
        COUNT(pa.Id) AS PostCount,
        AVG(pa.ViewCount) AS AvgViewCount
    FROM 
        Posts pa
    WHERE 
        pa.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        pa.OwnerUserId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostId,
    ua.Title,
    ua.PostCreationDate,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    pr.TotalScore,
    pr.PostCount,
    pr.AvgViewCount
FROM 
    UserActivity ua
LEFT JOIN 
    PostVoteStatistics ps ON ua.PostId = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON ua.PostId = cp.PostId
LEFT JOIN 
    PostRankings pr ON ua.UserId = pr.UserId
WHERE 
    ua.ActivityRank <= 5
ORDER BY 
    ua.Reputation DESC, 
    ua.PostCreationDate ASC;
