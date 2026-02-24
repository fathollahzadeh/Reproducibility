
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 9 THEN 1 END) AS BountyCloseVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostsWithVotes AS (
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.BountyCloseVotes, 0) AS BountyCloseVotes
    FROM
        Posts p
    LEFT JOIN
        PostVoteSummary v ON p.Id = v.PostId
)
SELECT
    r.PostId,
    r.Title,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ub.BadgeNames,
    pwv.UpVotes,
    pwv.DownVotes,
    pwv.BountyCloseVotes,
    CASE 
        WHEN pwv.UpVotes > pwv.DownVotes THEN 'Positive Engagement'
        WHEN pwv.UpVotes < pwv.DownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM
    RankedPosts r
JOIN
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN
    UserBadges ub ON u.Id = ub.UserId
JOIN
    PostsWithVotes pwv ON r.PostId = pwv.Id
WHERE
    r.Rank <= 5 
ORDER BY
    r.PostTypeId, r.Rank;
