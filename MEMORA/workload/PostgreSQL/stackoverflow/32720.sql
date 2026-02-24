WITH RECURSIVE PostHierarchy AS (
    SELECT Id, ParentId, Title, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON ph.Id = p.ParentId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopPostInfo AS (
    SELECT 
        p.Id,
        p.Title,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank,
        ph.Level AS PostLevel,
        ue.TotalVotes,
        ue.UpVotes,
        ue.DownVotes
    FROM Posts p
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN UserEngagement ue ON p.OwnerUserId = ue.UserId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
ClosedPostDetails AS (
    SELECT 
        tpi.Id AS PostId,
        tpi.Title,
        cp.FirstClosedDate,
        tpi.PostLevel,
        tpi.Rank,
        tpi.TotalVotes
    FROM TopPostInfo tpi
    JOIN ClosedPosts cp ON tpi.Id = cp.PostId
)
SELECT 
    cpd.PostId,
    cpd.Title,
    cpd.FirstClosedDate,
    cpd.PostLevel,
    cpd.Rank,
    COALESCE(cpd.TotalVotes, 0) AS TotalVotes,
    COALESCE(ue.UpVotes, 0) AS UpVotes,
    COALESCE(ue.DownVotes, 0) AS DownVotes
FROM ClosedPostDetails cpd
LEFT JOIN UserEngagement ue ON cpd.PostId = ue.UserId
ORDER BY cpd.Rank;