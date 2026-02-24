
WITH UserScoreBreakdown AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM
        UserScoreBreakdown
    WHERE
        PostCount > 0
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY
        ph.PostId
)
SELECT
    u.DisplayName,
    u.TotalScore,
    COALESCE(c.CloseCount, 0) AS ClosedPosts,
    CASE
        WHEN u.TotalScore > 1000 THEN 'High Contributor'
        WHEN u.TotalScore BETWEEN 500 AND 1000 THEN 'Moderate Contributor'
        ELSE 'Low Contributor'
    END AS ContributorType
FROM
    TopUsers u
LEFT JOIN
    ClosedPosts c ON u.UserId = c.PostId
WHERE
    u.Rank <= 10
ORDER BY
    u.TotalScore DESC, u.DisplayName ASC;
