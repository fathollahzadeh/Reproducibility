
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        COALESCE(po.OwnerUserId, -1) AS EffectiveOwnerId,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Posts po ON p.AcceptedAnswerId = po.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, po.OwnerUserId, p.AnswerCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MIN(u.CreationDate) AS AccountCreationDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS DeletionVotes,
        COUNT(CASE WHEN v.VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS PostHistoryTypes,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(*) AS TotalHistoryChanges,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureChanges
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    ua.DisplayName AS Owner,
    ua.PostsCreated,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COALESCE(pv.DeletionVotes, 0) AS DeletionVotes,
    COALESCE(pv.ReopenVotes, 0) AS ReopenVotes,
    phs.PostHistoryTypes,
    phs.FirstChangeDate,
    phs.LastChangeDate,
    phs.TotalHistoryChanges,
    phs.ClosureChanges,
    CASE 
        WHEN pd.CreationDate < ua.AccountCreationDate THEN 'Historical Activity'
        ELSE 'Recent Activity'
    END AS ActivityStatus
FROM PostDetails pd
JOIN UserActivity ua ON pd.EffectiveOwnerId = ua.UserId
LEFT JOIN PostVotes pv ON pd.PostId = pv.PostId
LEFT JOIN PostHistorySummary phs ON pd.PostId = phs.PostId
WHERE pd.Score > 0
ORDER BY pd.ViewCount DESC, pd.Score DESC
LIMIT 50;
