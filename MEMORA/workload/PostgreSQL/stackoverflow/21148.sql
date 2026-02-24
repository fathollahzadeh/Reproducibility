WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        LastAccessDate, 
        CASE 
            WHEN Reputation >= 1000 THEN 'Experienced'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Intermediate'
            ELSE 'Beginner'
        END AS ReputationLevel
    FROM Users
),
PostSummary AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
PostLinksSummary AS (
    SELECT 
        pl.PostId, 
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM PostLinks pl
    GROUP BY pl.PostId
),
RankingSummary AS (
    SELECT 
        ps.PostId, 
        ps.OwnerUserId,
        ps.UpVotesCount, 
        ps.DownVotesCount, 
        ps.CommentCount, 
        pls.RelatedPostCount,
        ROW_NUMBER() OVER (PARTITION BY us.ReputationLevel ORDER BY ps.UpVotesCount - ps.DownVotesCount DESC) AS Rank
    FROM PostSummary ps
    LEFT JOIN PostLinksSummary pls ON ps.PostId = pls.PostId
    JOIN UserReputation us ON ps.OwnerUserId = us.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS OpenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rs.PostId,
    u.DisplayName AS OwnerDisplayName,
    rs.UpVotesCount,
    rs.DownVotesCount,
    rs.CommentCount,
    rs.RelatedPostCount,
    rs.Rank,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.OpenCount, 0) AS OpenCount,
    CASE 
        WHEN rs.Rank < 10 THEN 'Top Posts'
        ELSE 'Others'
    END AS Category
FROM RankingSummary rs
JOIN Users u ON rs.OwnerUserId = u.Id
LEFT JOIN ClosedPosts cp ON rs.PostId = cp.PostId
WHERE rs.Rank <= 20
ORDER BY u.Reputation DESC, rs.Rank;