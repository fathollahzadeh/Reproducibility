WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
        AND p.Score IS NOT NULL
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
    HAVING 
        COUNT(v.Id) > 10
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted' ELSE 'Active' END) AS Status
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
),
AggregateData AS (
    SELECT 
        p.PostId,
        MAX(v.AdjustedVotes) AS MaxAdjustedVotes,
        COUNT(DISTINCT e.UserId) AS EditorsCount,
        MAX(h.LastEditDate) AS LatestEditDate
    FROM 
        RankedPosts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS AdjustedVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.PostId = v.PostId
    LEFT JOIN 
        PostHistoryAnalysis h ON p.PostId = h.PostId
    LEFT JOIN 
        (SELECT DISTINCT PostId, UserId 
        FROM PostHistory) e ON p.PostId = e.PostId
    GROUP BY 
        p.PostId
)

SELECT 
    a.PostId,
    p.Title,
    a.MaxAdjustedVotes,
    u.DisplayName,
    p.ViewCount,
    p.CreationDate,
    a.EditorsCount,
    a.LatestEditDate,
    COALESCE(h.Status, 'N/A') AS HistoryStatus
FROM 
    AggregateData a
JOIN 
    Posts p ON a.PostId = p.Id
LEFT JOIN 
    PopularUsers u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryAnalysis h ON a.PostId = h.PostId
WHERE 
    p.ViewCount > 100
ORDER BY 
    a.MaxAdjustedVotes DESC NULLS LAST,
    p.CreationDate DESC;