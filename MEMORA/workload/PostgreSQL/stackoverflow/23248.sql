
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeVotes,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRow
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostMeta AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.CommentCount,
        pm.TotalBounty,
        pm.LastEditDate,
        RANK() OVER (ORDER BY pm.TotalBounty DESC, pm.CommentCount DESC) AS PostRank
    FROM PostMeta pm
    WHERE pm.LastEditDate IS NOT NULL
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.PositiveVotes,
    ua.NegativeVotes,
    ua.AvgViews,
    rp.Title,
    rp.CommentCount,
    rp.TotalBounty,
    rp.LastEditDate,
    CASE 
        WHEN ua.PostCount = 0 THEN 'Newbie'
        WHEN ua.PostCount BETWEEN 1 AND 10 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM UserActivity ua
LEFT JOIN RankedPosts rp ON rp.PostRank <= 5
WHERE (ua.PositiveVotes > ua.NegativeVotes OR ua.AvgViews > 100)
  AND ua.UserRow = 1 
ORDER BY ua.PositiveVotes DESC, ua.AvgViews DESC;
