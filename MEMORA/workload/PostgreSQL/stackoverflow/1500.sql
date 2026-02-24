
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END), 0) AS DeleteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY UPPER(ps.Title) ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank,
        ps.CloseCount,
        ps.DeleteCount
    FROM 
        PostStatistics ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    rp.Title AS PostTitle,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViews,
    ups.UpVotes,
    ups.DownVotes,
    ups.AcceptedAnswers,
    rp.CloseCount,
    rp.DeleteCount
FROM 
    UserVoteSummary ups
JOIN 
    RankedPosts rp ON ups.UserId IN (
        SELECT DISTINCT p.OwnerUserId
        FROM Posts p
        WHERE p.Id = rp.PostId
    )
WHERE 
    ups.UpVotes > ups.DownVotes 
    AND rp.Rank <= 5
ORDER BY 
    ups.UpVotes DESC, rp.Score DESC;
