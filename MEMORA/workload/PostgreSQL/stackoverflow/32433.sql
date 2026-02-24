
WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM
        Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE
        p.PostTypeId = 2 
),

PostVoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM
        Votes
    GROUP BY
        PostId
),

PostHistorySummary AS (
    SELECT
        PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosedDate
    FROM
        PostHistory
    GROUP BY
        PostId
),

UserBadgeSummary AS (
    SELECT
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
)

SELECT
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Level,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastClosedDate,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM
    PostHierarchy ph
LEFT JOIN
    PostVoteSummary pvs ON ph.PostId = pvs.PostId
LEFT JOIN
    PostHistorySummary phs ON ph.PostId = phs.PostId
LEFT JOIN
    Posts post ON ph.PostId = post.Id
LEFT JOIN
    Users u ON post.OwnerUserId = u.Id
LEFT JOIN
    UserBadgeSummary ub ON u.Id = ub.UserId
WHERE
    (ph.Level = 0 AND (pvs.TotalVotes IS NULL OR pvs.TotalVotes > 5)) 
OR
    (ph.Level > 0 AND (pvs.UpVotes > pvs.DownVotes OR (phs.LastClosedDate IS NULL)));
