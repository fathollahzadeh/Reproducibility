
WITH RecursivePostHistory AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM
        PostHistory ph
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END), 0) AS AcceptedAnswers,
        AVG(v.BountyAmount) AS AverageBounty
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT
        p.Id AS PostId,
        ph.UserId AS CloserUserId,
        ph.CreationDate AS ClosedDate,
        pr.Name AS CloseReason,
        u.DisplayName AS CloserDisplayName
    FROM
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes pr ON CAST(ph.Comment AS integer) = pr.Id AND ph.PostHistoryTypeId = 10
    JOIN Users u ON ph.UserId = u.Id
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.PositivePosts,
    ups.AcceptedAnswers,
    ups.AverageBounty,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(cp.ClosedPostDetails, 'No Closed Posts') AS ClosedPostDetails
FROM
    UserPostStats ups
LEFT JOIN (
    SELECT
        CloserUserId,
        COUNT(PostId) AS ClosedPostCount,
        STRING_AGG(CONCAT('Post ID: ', PostId, ', Closed By: ', CloserDisplayName, ' on ', ClosedDate, ' (Reason: ', CloseReason, ')'), '; ') AS ClosedPostDetails
    FROM
        ClosedPosts
    GROUP BY
        CloserUserId
) cp ON ups.UserId = cp.CloserUserId
WHERE
    ups.TotalPosts > 0
ORDER BY
    ups.TotalPosts DESC,
    ups.PositivePosts DESC;
