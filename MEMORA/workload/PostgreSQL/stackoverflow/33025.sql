WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
RecentEdits AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserId AS EditorId,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalQuestions
    FROM
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        COUNT(DISTINCT p.Id) > 5 
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM
        Posts p
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    GROUP BY
        p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    rp.UserReputation,
    re.EditCount,
    tu.DisplayName AS TopUser,
    tu.TotalBounty,
    pvs.VoteCount
FROM
    RankedPosts rp
    LEFT JOIN RecentEdits re ON rp.PostId = re.PostId
    LEFT JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
    LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.PostId
WHERE
    rp.Rank <= 3 
ORDER BY
    rp.UserReputation DESC,
    rp.CreationDate DESC;