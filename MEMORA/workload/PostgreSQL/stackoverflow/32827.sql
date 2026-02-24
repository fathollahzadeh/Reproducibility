WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE u.Reputation > 1000 
    GROUP BY u.Id, u.DisplayName
), ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
), UserBadgeSummary AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
), PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(cp.CloseCount, 0) AS TotalClosures,
        ub.BadgeCount,
        ub.BadgeNames
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
    LEFT JOIN UserBadgeSummary ub ON u.Id = ub.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    COALESCE(ur.QuestionCount, 0) AS OwnerQuestionCount,
    COALESCE(ur.TotalViews, 0) AS OwnerTotalViews,
    COALESCE(ur.AverageBounty, 0) AS OwnerAverageBounty,
    pd.TotalClosures,
    pd.BadgeCount,
    pd.BadgeNames
FROM PostDetails pd
LEFT JOIN UserActivity ur ON pd.OwnerDisplayName = ur.DisplayName
WHERE pd.TotalClosures > 0
ORDER BY pd.TotalClosures DESC, pd.OwnerDisplayName;