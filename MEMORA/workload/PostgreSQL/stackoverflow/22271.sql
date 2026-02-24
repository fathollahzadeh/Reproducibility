
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(CASE WHEN rp.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN rp.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(rp.ViewCount) AS AvgViews,
        MAX(rp.CreationDate) AS LastPostDate
    FROM
        RecentPosts rp
    GROUP BY
        rp.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS Edits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS Closures,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS Deletions
    FROM
        PostHistory ph
    GROUP BY
        ph.UserId
),
FlaggedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.AvgViews, 0) AS AvgViews,
        COALESCE(pa.TotalEdits, 0) AS TotalEdits,
        COALESCE(pa.Closures, 0) AS TotalClosures,
        COALESCE(pa.Deletions, 0) AS TotalDeletions
    FROM
        Users u
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN PostHistoryAnalysis pa ON u.Id = pa.UserId
    WHERE
        u.Reputation > 1000 OR EXISTS (
            SELECT 1 
            FROM Badges b 
            WHERE b.UserId = u.Id AND (b.Class = 1 OR b.Class = 2)
        )
),
UserFlags AS (
    SELECT
        fu.UserId,
        fu.DisplayName,
        fu.Reputation,
        fu.TotalPosts,
        fu.TotalQuestions,
        fu.TotalAnswers,
        fu.AvgViews,
        fu.TotalEdits,
        fu.TotalClosures,
        fu.TotalDeletions,
        CASE 
            WHEN fu.TotalPosts < 5 THEN 'Newbie'
            WHEN fu.TotalPosts BETWEEN 5 AND 20 THEN 'Regular'
            ELSE 'Veteran'
        END AS UserType,
        CASE 
            WHEN fu.Reputation < 5000 THEN 'Low Reputation'
            WHEN fu.Reputation BETWEEN 5000 AND 10000 THEN 'Moderate Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM
        FlaggedUsers fu
)
SELECT
    uf.DisplayName,
    uf.UserType,
    uf.ReputationCategory,
    uf.TotalPosts,
    uf.TotalQuestions,
    uf.TotalAnswers,
    uf.AvgViews,
    uf.TotalEdits,
    uf.TotalClosures,
    uf.TotalDeletions,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM
    UserFlags uf
LEFT JOIN Votes v ON uf.UserId = v.UserId
GROUP BY
    uf.UserId, uf.DisplayName, uf.Reputation, 
    uf.UserType, uf.ReputationCategory, 
    uf.TotalPosts, uf.TotalQuestions, uf.TotalAnswers,
    uf.AvgViews, uf.TotalEdits, uf.TotalClosures, uf.TotalDeletions
ORDER BY
    uf.TotalPosts DESC, uf.Reputation DESC;
