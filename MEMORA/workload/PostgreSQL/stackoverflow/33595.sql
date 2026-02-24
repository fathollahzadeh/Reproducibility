
WITH RecursivePostHistories AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM
        PostHistory ph
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY
        p.Id
),
RecentUserActivities AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyContributed
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    WHERE
        u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days'
    GROUP BY
        u.Id, u.DisplayName
),
ClosedPostReason AS (
    SELECT
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INTEGER)
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
)

SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    pu.DisplayName AS OwnerDisplayName,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    rpa.Comment AS RecentActivityComment,
    rpa.CreationDate AS RecentActivityDate,
    COALESCE(cpr.CloseReasons, 'Not Closed') AS CloseReasons,
    u.PostsCreated,
    u.TotalBountyContributed
FROM
    Posts p
JOIN
    Users pu ON p.OwnerUserId = pu.Id
JOIN
    PostVoteSummary ps ON p.Id = ps.PostId
LEFT JOIN
    RecursivePostHistories rpa ON p.Id = rpa.PostId AND rpa.rn = 1
LEFT JOIN
    ClosedPostReason cpr ON p.Id = cpr.PostId
LEFT JOIN
    RecentUserActivities u ON u.UserId = pu.Id
WHERE
    p.AnswerCount > 0
    AND p.ViewCount > 100
ORDER BY
    p.CreationDate DESC
LIMIT 50;
