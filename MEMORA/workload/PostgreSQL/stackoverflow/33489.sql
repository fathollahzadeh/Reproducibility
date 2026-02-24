WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(ps.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.CreationDate,
        p.Title,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId
    ) ps ON p.Id = ps.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, ps.VoteCount, c.CommentCount
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COALESCE(stats.UpVotesCount, 0) - COALESCE(stats.DownVotesCount, 0) AS NetVotes
    FROM 
        Users u
    LEFT JOIN UserVoteStats stats ON u.Id = stats.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.VoteCount,
    ps.CommentCount,
    pr.ReputationRank,
    COUNT(DISTINCT r.UserId) AS UniqueUserInteractions,
    MAX(ps.LastClosedDate) AS LastClosed,
    MAX(ps.LastReopenedDate) AS LastReopened
FROM 
    PostStatistics ps
    JOIN RecursivePostHistory r ON ps.PostId = r.PostId
    JOIN UserRankings pr ON r.UserId = pr.UserId
GROUP BY 
    ps.PostId, ps.Title, ps.VoteCount, ps.CommentCount, pr.ReputationRank
ORDER BY 
    ps.VoteCount DESC, ps.CommentCount DESC, pr.ReputationRank
LIMIT 100;