
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id AS HistoryId,
        p.Title AS PostTitle,
        u.DisplayName AS UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        Users u ON ph.UserId = u.Id
), 
LatestPostHistory AS (
    SELECT 
        HistoryId,
        PostTitle,
        UserDisplayName,
        CreationDate,
        Comment,
        PostHistoryTypeId
    FROM 
        RecursivePostHistory
    WHERE 
        rn = 1
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        p.CreationDate,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 86400 AS AgeInDays
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.CreationDate
), 
TopPosts AS (
    SELECT
        ps.PostId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CloseCount,
        ps.AgeInDays,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    pp.PostId,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.CloseCount,
    pp.AgeInDays,
    lph.PostTitle,
    lph.UserDisplayName,
    lph.CreationDate AS LastUpdated
FROM 
    TopPosts pp
LEFT JOIN 
    LatestPostHistory lph ON pp.PostId = lph.HistoryId
WHERE 
    pp.Rank <= 10
ORDER BY 
    pp.Rank;
