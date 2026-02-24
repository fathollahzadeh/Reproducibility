
WITH RECURSIVE UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(uh.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(uh.TotalQuestions, 0) AS UserTotalQuestions,
        COALESCE(uh.TotalAnswers, 0) AS UserTotalAnswers,
        COALESCE(uh.TotalScore, 0) AS UserTotalScore
    FROM Posts p
    LEFT JOIN UserPosts uh ON p.OwnerUserId = uh.UserId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS ClosureReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId, ph.CreationDate
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserTotalPosts,
    rp.UserTotalQuestions,
    rp.UserTotalAnswers,
    rp.UserTotalScore,
    cp.ClosureReasons
FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.PostRank <= 10 
ORDER BY rp.Score DESC, rp.ViewCount DESC;
