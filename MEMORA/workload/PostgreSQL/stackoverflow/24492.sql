WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryDate,
        ph.UserId,
        COUNT(ph.Id) OVER (PARTITION BY p.Id) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEditRank,
        ph.Comment 
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
), 
AggregateVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 
                 WHEN vt.Name = 'DownMod' THEN -1 
                 ELSE 0 END) AS ScoreDifference
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
RecentTopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)

SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    rph.HistoryDate,
    rph.UserId,
    u.DisplayName AS EditorDisplayName,
    rph.EditCount,
    av.ScoreDifference,
    rt.UserId AS TopUserId,
    rt.DisplayName AS TopUserName,
    rt.ReputationRank
FROM 
    RecursivePostHistory rph
LEFT JOIN 
    Users u ON rph.UserId = u.Id
LEFT JOIN 
    AggregateVotes av ON rph.PostId = av.PostId
LEFT JOIN 
    RecentTopUsers rt ON rph.UserId = rt.UserId
WHERE 
    rph.RecentEditRank = 1 
    AND (av.ScoreDifference IS NULL OR av.ScoreDifference > 0)
    AND EXISTS (
        SELECT 1
        FROM Comments c
        WHERE c.PostId = rph.PostId
          AND (c.Text LIKE '%help%' OR c.Text LIKE '%advice%')
    )
ORDER BY 
    rph.HistoryDate DESC;