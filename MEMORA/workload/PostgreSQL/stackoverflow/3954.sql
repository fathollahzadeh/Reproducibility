WITH LatestPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryCounts AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN Ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosed
    FROM 
        PostHistory Ph
    GROUP BY 
        Ph.PostId
)
SELECT 
    lp.PostId,
    lp.Title,
    lp.CreationDate,
    lp.Tags,
    lp.OwnerName,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    phc.EditCount,
    CASE WHEN phc.IsClosed = 1 THEN 'Yes' ELSE 'No' END AS IsClosedPost
FROM 
    LatestPosts lp
LEFT JOIN 
    PostVoteSummary pvs ON lp.PostId = pvs.PostId
LEFT JOIN 
    PostHistoryCounts phc ON lp.PostId = phc.PostId
WHERE 
    lp.rn = 1
ORDER BY 
    lp.CreationDate DESC
LIMIT 100;