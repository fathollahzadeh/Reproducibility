
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS VoteBalance,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 END) AS ClosureOrDeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName,
    us.UpVotes,
    us.DownVotes,
    ps.VoteBalance,
    ps.CommentCount,
    ps.RelatedPostCount,
    ph.ClosedDate,
    ph.DeletedDate,
    ps.PostId
FROM 
    UserVoteSummary us
JOIN 
    Users u ON us.UserId = u.Id
JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    PostHistoryDetails ph ON ps.PostId = ph.PostId
WHERE 
    (us.PostCount > 5 OR us.UpVotes > us.DownVotes)
    AND (ph.ClosureOrDeletionCount = 0 OR (ph.ClosedDate IS NOT NULL AND ph.DeletedDate IS NULL))
ORDER BY 
    us.UpVotes DESC, 
    ps.VoteBalance DESC;
