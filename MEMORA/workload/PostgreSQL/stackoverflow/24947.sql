
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostVoteAnalytics AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        v.PostId
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ph.UserId AS CloserId
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11) 
),
FinalPostReport AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,  -- Added CreationDate to the SELECT clause
        rp.OwnerUserId AS PostOwner,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        pva.UpVotes,
        pva.DownVotes,
        cp.CloseReason
    FROM
        RankedPosts rp
    JOIN
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN
        PostVoteAnalytics pva ON rp.PostId = pva.PostId
    LEFT JOIN
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE
        rp.UserPostRank <= 5 
)
SELECT
    PostId,
    Title,
    Score,
    PostOwner,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    UpVotes,
    DownVotes,
    CASE
        WHEN CloseReason IS NOT NULL THEN 'Closed: ' || CloseReason
        ELSE 'Active'
    END AS Status
FROM
    FinalPostReport
ORDER BY
    Score DESC, CreationDate DESC  -- Added CreationDate to the ORDER BY clause
LIMIT 100;
