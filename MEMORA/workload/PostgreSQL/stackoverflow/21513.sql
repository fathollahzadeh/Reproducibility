WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (6, 7)) AS CloseReopenVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalPositiveVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalNegativeVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(p.Score) AS TotalScore,
        COALESCE(MAX(ph.CreationDate), '1900-01-01') AS LastEditDate,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
EnhancedPostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.TotalScore,
        ps.LastEditDate,
        ps.BadgeCount,
        ps.CloseCount,
        CASE 
            WHEN ps.CloseCount > 0 THEN 'Closed'
            WHEN ps.TotalScore > 10 THEN 'Popular'
            ELSE 'Normal'
        END AS PostCategory,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.TotalScore DESC) AS ScoreRank
    FROM PostSummary ps
    LEFT JOIN Users u ON ps.OwnerUserId = u.Id
)
SELECT 
    epd.OwnerDisplayName,
    epd.Title,
    epd.TotalScore,
    epd.CommentCount,
    epd.PostCategory,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.CloseReopenVotes,
    epd.BadgeCount,
    CASE 
        WHEN epd.TotalScore = 0 THEN 'Neutral'
        WHEN epd.TotalScore > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS ScoreStatus,
    CASE 
        WHEN epd.LastEditDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Outdated'
        ELSE 'Recent'
    END AS EditRecency
FROM EnhancedPostDetails epd
JOIN UserVoteSummary uvs ON epd.OwnerUserId = uvs.UserId
WHERE epd.ScoreRank <= 5
ORDER BY epd.TotalScore DESC, uvs.UpVotes DESC;