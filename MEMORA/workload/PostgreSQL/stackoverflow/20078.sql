
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT v.UserId) AS VoterCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        MIN(ph.CreationDate) AS FirstEditedDate,
        MAX(ph.CreationDate) AS LastEditedDate,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 4 THEN 'Edited Title'
                                 WHEN ph.PostHistoryTypeId = 5 THEN 'Edited Body'
                                 ELSE 'Other' END, ', ') AS EditTypes
    FROM PostHistory ph
    GROUP BY ph.PostId
),
UserPostInfo AS (
    SELECT 
        u.Id AS UserId,
        COUNT(ap.PostId) AS ActivePostCount,
        SUM(ph.EditCount) AS TotalEdits,
        STRING_AGG(DISTINCT ph.EditTypes, '; ') AS EditTypesSummary,
        MAX(r.UserRank) AS HighestUserRank
    FROM Users u
    LEFT JOIN ActivePosts ap ON u.Id = ap.OwnerUserId
    LEFT JOIN PostHistoryStats ph ON ap.PostId = ph.PostId
    LEFT JOIN RankedUsers r ON u.Id = r.UserId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    ui.ActivePostCount,
    ui.TotalEdits,
    ui.EditTypesSummary,
    u.Reputation,
    COALESCE(r.UserRank, 0) AS UserRank,
    CASE 
        WHEN ui.TotalEdits > 0 THEN 'Active Editor'
        ELSE 'Inactive Editor'
    END AS EditorStatus,
    COALESCE(ui.HighestUserRank, 0) AS HighestUserRank
FROM Users u
LEFT JOIN UserPostInfo ui ON u.Id = ui.UserId
LEFT JOIN RankedUsers r ON u.Id = r.UserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY ui.ActivePostCount DESC, u.Reputation DESC;
