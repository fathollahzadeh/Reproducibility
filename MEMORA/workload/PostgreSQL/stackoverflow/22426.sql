
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(rp.Rank, 0) AS PostRank,
        COALESCE(ui.UpVotes, 0) AS TotalUpVotes,
        COALESCE(ui.DownVotes, 0) AS TotalDownVotes,
        COALESCE(ui.CommentCount, 0) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    LEFT JOIN 
        UserInteractions ui ON p.OwnerUserId = ui.UserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::INTEGER = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.PostRank,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.TotalComments,
    cr.CloseReasonNames
FROM 
    PostStatistics ps
LEFT JOIN 
    CloseReasons cr ON ps.PostId = cr.PostId
WHERE 
    ps.PostRank <= 5 
    AND ps.TotalUpVotes - ps.TotalDownVotes > 0 
ORDER BY 
    ps.TotalUpVotes DESC, ps.PostRank ASC
LIMIT 10;
