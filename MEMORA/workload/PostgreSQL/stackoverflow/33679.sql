
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Rank,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons,
    tu.UserId,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalScore AS TopUserScore,
    tu.PostCount AS TopUserPostCount
FROM
    RankedPosts rp
LEFT JOIN
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN
    TopUsers tu ON EXISTS (
        SELECT 1
        FROM Posts p 
        WHERE p.OwnerUserId = tu.UserId AND p.Id = rp.PostId
    )
WHERE
    rp.Rank <= 10
ORDER BY
    rp.Score DESC, rp.CreationDate DESC;
