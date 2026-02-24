
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), 
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.CommentCount,
        pd.CloseCount,
        pd.ReopenCount,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    ups.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Rank,
    ups.UpVotes,
    ups.DownVotes,
    rp.CommentCount,
    rp.CloseCount,
    rp.ReopenCount
FROM 
    UserVoteStats ups
JOIN 
    RankedPosts rp ON ups.TotalPosts > 0
WHERE 
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = ups.UserId 
        AND p.Id = rp.PostId
    )
ORDER BY 
    rp.Rank, ups.UpVotes DESC;
